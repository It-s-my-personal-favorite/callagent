import argparse
import asyncio
import base64
import hashlib
import json
import os
import subprocess
import sys
import threading
import websocket
import boto3
from pathlib import Path
from datetime import datetime
from botocore.exceptions import ClientError
from flask import Flask, jsonify, request
from flask_sock import Sock
from twilio.twiml.voice_response import VoiceResponse, Connect, Stream

# Pipecat Imports
from pipecat.frames.frames import EndFrame, AudioRawFrame
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.task import PipelineParams, PipelineTask
from pipecat.services.cartesia import CartesiaTTSService
from pipecat.services.deepgram import DeepgramSTTService
from pipecat.services.google import GoogleLLMService # Google AI Studio Service
from pipecat.transports.network.helpers.twilio_utils import TwilioFrameSerializer

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

    with app.app_context():
        if drop_all: db.drop_all()
        db.create_all()

    # --- EXISTING RECORDING LOGIC ---
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

    # --- PIPECAT + GOOGLE AI STUDIO ---
    async def run_pipecat(ws, audio_buffer, stream_sid):
        serializer = TwilioFrameSerializer(stream_sid)
        
        # 1. Services Setup
        stt = DeepgramSTTService(api_key=Config.DEEPGRAM_API_KEY)
        
        # Using Gemini 1.5 Flash for the lowest possible latency
        llm = GoogleLLMService(
            model=Config.GEMINI_MODEL,
            api_key=Config.GEMINI_API_KEY # Ensure this is in your config
        )
        
        tts = CartesiaTTSService(
            api_key=Config.CARTESIA_API_KEY, 
            voice_id="79a125e8-cd45-4c13-9125-278b3011a814" # Cartesia Sonic English/German
        )

        pipeline = Pipeline([stt, llm, tts])
        task = PipelineTask(pipeline, PipelineParams(allow_interruptions=True))

        # Initial Prompt (Thorsten persona)
        @task.on_first_frame
        async def on_first_frame(task):
            await task.queue_frames([
                # You can inject a system message or an initial greeting here
                {"role": "system", "content": "Du bist Thorsten, ein hilfreicher KI-Assistent. Antworte kurz und prägnant."}
            ])

        # AI -> Twilio Output
        async def push_to_twilio():
            async for frame in tts.get_event_iterator():
                if isinstance(frame, AudioRawFrame):
                    ws.send(serializer.serialize(frame))
                elif isinstance(frame, EndFrame):
                    break

        outbound_thread = asyncio.create_task(push_to_twilio())

        # Twilio -> (AI + S3 Buffer)
        try:
            while True:
                message = ws.receive(timeout=0)
                if message is None: break
                
                data = json.loads(message)
                if data.get("event") == "media":
                    # Path A: To Google AI Studio (LLM) via STT
                    await task.queue_frame(serializer.deserialize(message))
                    # Path B: To Local Buffer (S3 Recording)
                    audio_buffer.extend(base64.b64decode(data["media"]["payload"]))
                elif data.get("event") == "stop":
                    break
                await asyncio.sleep(0.001)
        finally:
            await task.queue_frame(EndFrame())
            await outbound_thread

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

    @sock.route("/audiostream/<call_sid>")
    def audio_stream(ws, call_sid):
        audio_buffer = bytearray()
        stream_sid = None

        while not stream_sid:
            msg = ws.receive()
            if not msg: return
            data = json.loads(msg)
            if data.get("event") == "start":
                stream_sid = data["start"]["streamSid"]

        # Block this thread while the AI conversation runs
        asyncio.run(run_pipecat(ws, audio_buffer, stream_sid))

        # After call: Process and upload to Wasabi
        if len(audio_buffer) > 0:
            threading.Thread(target=process_and_upload_audio, 
                             args=(audio_buffer.copy(), stream_sid, call_sid)).start()

    return app

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--drop-all", action="store_true")
    args = parser.parse_args()
    application = create_app(drop_all=args.drop_all)
    application.run(host="0.0.0.0", port=5000)