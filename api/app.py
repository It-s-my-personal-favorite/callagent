import argparse
import asyncio
import base64
import hashlib
import json
import os
import subprocess
import sys
import threading
import uuid
import websocket
import traceback
import audioop
import boto3
from pathlib import Path
from datetime import datetime
from botocore.exceptions import ClientError
from flask import Flask, jsonify, request
from flask_sock import Sock
from twilio.twiml.voice_response import VoiceResponse, Connect, Stream
from simple_websocket.ws import ConnectionClosed

# 1. Core Pipeline Imports
from pipecat.frames.frames import EndFrame, AudioRawFrame, TextFrame
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.task import PipelineParams, PipelineTask
from pipecat.processors.frame_processor import FrameProcessor

# 2. Services (Now using specific sub-modules to avoid DeprecationWarnings)
from pipecat.services.cartesia.tts import CartesiaTTSService
from pipecat.services.deepgram.stt import DeepgramSTTService
from pipecat.services.google.llm import GoogleLLMService

# 3. Serializers (This fixes your ModuleNotFoundError)
from pipecat.serializers.twilio import TwilioFrameSerializer

# Support pathing
try:
    from config import Config
except ModuleNotFoundError:
    root_dir = Path(__file__).resolve().parent.parent
    if str(root_dir) not in sys.path:
        sys.path.insert(0, str(root_dir))
    from config import Config

try:
    from api.database import ensure_database_exists
    from api.models import CallRecord, db
except ModuleNotFoundError:
    from database import ensure_database_exists
    from models import CallRecord, db

# --- EXISTING WASABI CLIENT ---
s3_client = boto3.client(
    's3',
    endpoint_url=Config.WASABI_ENDPOINT_URL,
    aws_access_key_id=Config.WASABI_ACCESS_KEY,
    aws_secret_access_key=Config.WASABI_SECRET_KEY
)

def upload_to_wasabi_and_get_link(local_file_path, object_name):
    try:
        s3_client.upload_file(local_file_path, Config.WASABI_BUCKET_NAME, object_name)
        return s3_client.generate_presigned_url(
            'get_object',
            Params={'Bucket': Config.WASABI_BUCKET_NAME, 'Key': object_name, 'ResponseContentType': 'audio/mp4'},
            ExpiresIn=3600
        )
    except ClientError: return None

def create_app(drop_all: bool = False) -> Flask:
    ensure_database_exists()
    app = Flask(__name__)
    app.config.from_object(Config)
    sock = Sock(app)
    db.init_app(app)

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"}), 200

    def run_async(coro):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        return loop.run_until_complete(coro)

    with app.app_context():
        if drop_all: db.drop_all()
        db.create_all()

    @app.get("/api/calls")
    def list_calls():
        records = (
            db.session.query(CallRecord)
            .order_by(CallRecord.call_start.desc())
            .all()
        )
        return jsonify([record.to_dict() for record in records]), 200

    @app.post("/api/calls")
    def create_call():
        payload = request.get_json(silent=True) or {}

        from_phone_number = (
            payload.get("from_phone_number")
            or payload.get("phone_number")
            or payload.get("from")
            or ""
        )
        to_phone_number = payload.get("to_phone_number") or payload.get("to") or ""

        if not from_phone_number:
            return jsonify({"error": "Missing required field: phone_number"}), 400

        call_sid = payload.get("call_sid") or f"TEST_{uuid.uuid4().hex[:24]}"

        call_start = datetime.utcnow()
        chat_date = payload.get("chat_date")
        call_time = payload.get("call_time")
        if chat_date and call_time:
            try:
                call_start = datetime.strptime(f"{chat_date} {call_time}", "%Y-%m-%d %H:%M")
            except ValueError:
                return jsonify({"error": "Invalid chat_date/call_time format"}), 400

        record = CallRecord(
            call_sid=call_sid,
            from_phone_number=from_phone_number,
            to_phone_number=to_phone_number or from_phone_number,
            call_start=call_start,
        )
        db.session.add(record)
        db.session.commit()

        return jsonify(record.to_dict()), 201

    def process_and_upload_audio(raw_audio_bytes, stream_sid, call_sid):
        AUDIO_DIR = os.path.join(os.getcwd(), 'temp_audio')
        os.makedirs(AUDIO_DIR, exist_ok=True)
        file_hash = hashlib.sha256(stream_sid.encode('utf-8')).hexdigest()[:32]
        raw_path = os.path.join(AUDIO_DIR, f"{file_hash}.ulaw")
        out_path = os.path.join(AUDIO_DIR, f"{file_hash}.m4a")
        
        try:
            with open(raw_path, 'wb') as f: f.write(raw_audio_bytes)
            subprocess.run(["ffmpeg", "-y", "-f", "mulaw", "-ar", "8000", "-i", raw_path, "-c:a", "aac", out_path], 
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            link = upload_to_wasabi_and_get_link(out_path, f"recordings/{file_hash}.m4a")
            if link and call_sid:
                with app.app_context():
                    db.session.query(CallRecord).filter_by(call_sid=call_sid).update({"recording_url": link})
                    db.session.commit()
        finally:
            for p in [raw_path, out_path]:
                if os.path.exists(p): os.remove(p)

    # A small helper to push frames to your Flask-Sock WebSocket
    class TwilioSink(FrameProcessor):
        def __init__(self, ws, serializer):
            super().__init__()
            self._ws = ws
            self._serializer = serializer

        async def process_frame(self, frame, direction):
            await super().process_frame(frame, direction)
            # If the frame contains audio, serialize and send it to Twilio
            if isinstance(frame, AudioRawFrame):
                try:
                    self._ws.send(self._serializer.serialize(frame))
                except Exception:
                    pass # WebSocket might be closed

    # --- PIPECAT + GOOGLE AI STUDIO ---
    async def run_pipecat(ws, audio_buffer, stream_sid, call_sid):
        serializer = TwilioFrameSerializer(
            stream_sid=stream_sid,
            call_sid=call_sid,
            account_sid=Config.TWILIO_ACCOUNT_SID,
            auth_token=Config.TWILIO_AUTH_TOKEN
        )

        # 1. Initialize Services
        stt = DeepgramSTTService(api_key=Config.DEEPGRAM_API_KEY)
        llm = GoogleLLMService(
            api_key=Config.GEMINI_API_KEY,
            settings=GoogleLLMService.Settings(
                model=Config.GEMINI_MODEL # likely "gemini-1.5-flash"
        )
)
        tts = CartesiaTTSService(api_key=Config.CARTESIA_API_KEY, settings=CartesiaTTSService.Settings(voice="e00dd3df-19e7-4cd4-827a-7ff6687b6954"))
        
        # 2. Our Outbound Sink
        sink = TwilioSink(ws, serializer)

        # 3. Create Pipeline (STT -> LLM -> TTS -> Sink)
        pipeline = Pipeline([stt, llm, tts, sink])
        task = PipelineTask(pipeline)
        params = PipelineParams(allow_interruptions=True)
        object.__setattr__(params, "loop", asyncio.get_running_loop())

        # 4. Handle the "Hello"
        async def on_first_frame(task):
            await task.queue_frame(TextFrame("Hi, ich bin Thorsten. Wie kann ich dir helfen?"))
        
        task.add_event_handler("on_first_frame", on_first_frame)
        runner_task = asyncio.create_task(task.run(params))

        # 6. Inbound Loop (Twilio -> AI)
        try:
            while True:
                # This is key! It prevents ws.receive from freezing the AI's speech
                message = await asyncio.to_thread(ws.receive, 0.01)
                    
                if message is None:
                    break

                data = json.loads(message)
                if data.get("event") == "media":
                    await task.queue_frame(serializer.deserialize(message))
                    audio_buffer.extend(base64.b64decode(data["media"]["payload"]))
                    
                elif data.get("event") == "stop":
                    break
                    
                # Yield to the event loop so the AI can process audio
                await asyncio.sleep(0.001)

        except Exception as e:
            print(f"Stream Error: {e}")
        finally:
            await task.queue_frame(EndFrame())
            await runner_task

    # --- FLASK ROUTES ---
    @app.post("/api/twilio/voice")
    def twilio_voice():
        record = CallRecord.create_from_request(request.form)
        db.session.add(record)
        db.session.commit()

        response = VoiceResponse()
        connect = Connect()
        # Connect Twilio to the WebSocket route below
        stream = Stream(url=f"wss://{Config.SELF_URL}/audiostream/{record.call_sid}")
        connect.append(stream)
        response.append(connect)
        return str(response), 200, {"Content-Type": "application/xml"}

    def generate_silence_ulaw(duration_ms=500):
        sample_rate = 8000
        num_samples = int(sample_rate * duration_ms / 1000)

        pcm = b"\x00\x00" * num_samples  # silence PCM 16-bit
        ulaw = audioop.lin2ulaw(pcm, 2)
        return ulaw

    @sock.route("/audiostream/<call_sid>")
    def audiostream(ws, call_sid):
        print("🟢 Connected")

        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

        async def handler():
            stream_sid = None

            try:
                while True:
                    try:
                        message = await asyncio.to_thread(ws.receive)
                    except ConnectionClosed:
                        print("🔌 Twilio disconnected")
                        break

                    if not message:
                        continue

                    data = json.loads(message)
                    event = data.get("event")

                    print("📦 Event:", event)

                    # 🚀 START EVENT
                    if event == "start":
                        stream_sid = data["start"]["streamSid"]
                        print("🚀 Stream:", stream_sid)

                        serializer = TwilioFrameSerializer(
                            stream_sid=stream_sid,
                            call_sid="demo",
                            account_sid="ACxxx",
                            auth_token="xxx"
                        )

                        # 🔧 SERVICES
                        stt = DeepgramSTTService(api_key=Config.DEEPGRAM_API_KEY)

                        llm = GoogleLLMService(
                            api_key=Config.GEMINI_API_KEY,
                            settings=GoogleLLMService.Settings(
                                model="gemini-1.5-flash"
                            )
                        )

                        tts = CartesiaTTSService(api_key=Config.CARTESIA_API_KEY)

                        # 🔊 CUSTOM SINK (IMPORTANT)
                        class TwilioSink(FrameProcessor):
                            async def process_frame(self, frame, direction):
                                if isinstance(frame, AudioRawFrame):
                                    try:
                                        # 🔥 Convert PCM → mulaw 8kHz
                                        pcm = frame.audio

                                        # ensure mono 16-bit
                                        mulaw = audioop.lin2ulaw(pcm, 2)

                                        payload = {
                                            "event": "media",
                                            "streamSid": stream_sid,
                                            "media": {
                                                "payload": base64.b64encode(mulaw).decode()
                                            }
                                        }

                                        await asyncio.to_thread(ws.send, json.dumps(payload))

                                    except Exception as e:
                                        print("Send error:", e)

                        sink = TwilioSink()

                        # 🔗 PIPELINE
                        pipeline = Pipeline([stt, llm, tts, sink])
                        task = PipelineTask(pipeline)

                        params = PipelineParams(allow_interruptions=True)
                        object.__setattr__(params, "loop", asyncio.get_running_loop())

                        asyncio.create_task(task.run(params))

                        # ✅ CRITICAL: immediate greeting
                        await task.queue_frame(TextFrame("Hi! How can I help you?"))

                    # 🎤 AUDIO IN
                    elif event == "media" and task:
                        frame = serializer.deserialize(message)
                        await task.queue_frame(frame)

                    # 🔴 STOP EVENT
                    elif event == "stop":
                        print("🔴 Stream stopped")
                        break

            except Exception as e:
                import traceback
                traceback.print_exc()

        loop.run_until_complete(handler())
        """
        # After call: Process and upload to Wasabi
        if len(audio_buffer) > 0:
            threading.Thread(target=process_and_upload_audio, 
                             args=(audio_buffer.copy(), stream_sid, call_sid)).start()
        """

    return app

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--drop-all", action="store_true")
    args = parser.parse_args()
    application = create_app(drop_all=args.drop_all)
    application.run(host="0.0.0.0", port=5000)
