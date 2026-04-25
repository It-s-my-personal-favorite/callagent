import argparse
from datetime import datetime
import hashlib
from pathlib import Path
import subprocess
import sys
import hashlib
import os
import boto3
from botocore.exceptions import ClientError

from flask import Flask, jsonify, request
from twilio.twiml.voice_response import VoiceResponse, Connect, Stream
from flask_sock import Sock
import websocket, threading, json, base64

# Support both execution modes:
# 1) from project root: python -m api.app
# 2) from api folder:   python -m app
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

# Initialize the S3 client pointing to Wasabi
s3_client = boto3.client(
    's3',
    endpoint_url=Config.WASABI_ENDPOINT_URL,
    aws_access_key_id=Config.WASABI_ACCESS_KEY,
    aws_secret_access_key=Config.WASABI_SECRET_KEY
)

def upload_to_wasabi_and_get_link(local_file_path, object_name):
    """
    Uploads a file to Wasabi and returns a secure URL for the frontend.
    """
    try:
        # 1. Upload the file
        print(f"Uploading {object_name} to Wasabi...")
        s3_client.upload_file(local_file_path, Config.WASABI_BUCKET_NAME, object_name)
        
        # 2. Generate a Pre-signed URL valid for 1 hour (3600 seconds)
        # Your frontend can use this URL directly in an <audio src="..."> tag
        presigned_url = s3_client.generate_presigned_url(
            'get_object',
            Params={
                'Bucket': Config.WASABI_BUCKET_NAME,
                'Key': object_name,
                # Optional: Force the browser to treat it as an audio file
                'ResponseContentType': 'audio/mp4' 
            },
            ExpiresIn=3600
        )
        
        print("Upload successful!")
        return presigned_url

    except ClientError as e:
        print(f"Wasabi upload failed: {e}")
        return None


def process_and_upload_audio(raw_audio_bytes, stream_sid, call_sid):
    """
    This runs in a separate thread AFTER the call hangs up, 
    so it doesn't block your Flask workers.
    """
    # Define your storage directory (relative to your app.py)
    AUDIO_DIR = os.path.join(os.getcwd(), 'temp_audio')
    os.makedirs(AUDIO_DIR, exist_ok=True)  # Creates the folder if it doesn't exist

    print(f"Background Task Started for {stream_sid}. Processing {len(raw_audio_bytes)} bytes.")

    # 1. Generate a unique hash for the filename using the stream_sid
    # We take the first 32 characters of a SHA-256 hash for a clean filename
    file_hash = hashlib.sha256(stream_sid.encode('utf-8')).hexdigest()[:32]
    
    # Define the final paths
    raw_filepath = os.path.join(AUDIO_DIR, f"{file_hash}.ulaw")
    final_m4a_filepath = os.path.join(AUDIO_DIR, f"{file_hash}.m4a")
    wasabi_object_name = f"recordings/{file_hash}.m4a" # Organizes it in a folder in Wasabi

    try:
        # 2. Save the raw buffer to a temporary file
        with open(raw_filepath, 'wb') as f:
            f.write(raw_audio_bytes)
        
        print(f"Successfully saved raw audio for {stream_sid}. Starting conversion to .m4a...")
        # 3. Convert the raw file to .m4a using FFmpeg
        # (This uses Python's os.system to run the command line tool)
        # Note: You must have ffmpeg installed on your server for this to work
        command = [
            "ffmpeg", "-y", 
            "-f", "mulaw", 
            "-ar", "8000", 
            "-i", raw_filepath, 
            "-c:a", "aac", 
            final_m4a_filepath
        ]

        # Run the command and route both standard output and errors to the OS-appropriate black hole
        subprocess.run(
            command, 
            stdout=subprocess.DEVNULL, 
            stderr=subprocess.DEVNULL
        )

        file_link = upload_to_wasabi_and_get_link(
            local_file_path=final_m4a_filepath, 
            object_name=wasabi_object_name
        )

        if file_link:
            if not call_sid:
                print("Call SID is missing.")
                return
            with app.app_context():
                db.session.query(CallRecord).filter_by(call_sid=call_sid).update({"recording_url": file_link})
                db.session.commit()

            print(f"File uploaded to Wasabi. Accessible at: {file_link}")
        
        # 4. Save the hash to your Database
        # pseudo-code: db.execute("INSERT INTO recordings (call_id, hash) VALUES (?, ?)", (stream_sid, file_hash))
        print(f"Successfully processed and saved. Database Hash: {file_hash}")
        
    finally:
    # 5. Clean up local disk (delete both the raw file and the m4a once uploaded)
        if os.path.exists(raw_filepath):
            os.remove(raw_filepath)
        if os.path.exists(final_m4a_filepath):
            os.remove(final_m4a_filepath)
    
    # 1. Save raw bytes to a temp file (e.g., temp_raw.ulaw)
    
    # 2. Use FFmpeg (via command line or pydub) to convert:
    #    ffmpeg -f mulaw -ar 8000 -i temp_raw.ulaw -c:a aac output.m4a
    
    # 3. Upload output.m4a to AWS S3 using the boto3 library
    #    s3_url = upload_to_s3("output.m4a")
    
    # 4. Save s3_url to your Database
    #    db.execute("INSERT INTO calls (id, audio_link) VALUES (?, ?)", (stream_sid, s3_url))
    
    # 5. Clean up temp files
    print(f"Finished processing audio for {stream_sid}")


def create_app(drop_all: bool = False) -> Flask:
    ensure_database_exists()

    app = Flask(__name__)
    app.config.from_object(Config)
    sock = sock = Sock(app)

    db.init_app(app)

    with app.app_context():
        if drop_all:
            db.drop_all()
        db.create_all()

    def process_and_upload_audio(raw_audio_bytes, stream_sid, call_sid):
        """
        This runs in a separate thread AFTER the call hangs up, 
        so it doesn't block your Flask workers.
        """
        # Define your storage directory (relative to your app.py)
        AUDIO_DIR = os.path.join(os.getcwd(), 'temp_audio')
        os.makedirs(AUDIO_DIR, exist_ok=True)  # Creates the folder if it doesn't exist

        print(f"Background Task Started for {stream_sid}. Processing {len(raw_audio_bytes)} bytes.")

        # 1. Generate a unique hash for the filename using the stream_sid
        # We take the first 32 characters of a SHA-256 hash for a clean filename
        file_hash = hashlib.sha256(stream_sid.encode('utf-8')).hexdigest()[:32]
        
        # Define the final paths
        raw_filepath = os.path.join(AUDIO_DIR, f"{file_hash}.ulaw")
        final_m4a_filepath = os.path.join(AUDIO_DIR, f"{file_hash}.m4a")
        wasabi_object_name = f"recordings/{file_hash}.m4a" # Organizes it in a folder in Wasabi

        try:
            # 2. Save the raw buffer to a temporary file
            with open(raw_filepath, 'wb') as f:
                f.write(raw_audio_bytes)
            
            print(f"Successfully saved raw audio for {stream_sid}. Starting conversion to .m4a...")
            # 3. Convert the raw file to .m4a using FFmpeg
            # (This uses Python's os.system to run the command line tool)
            # Note: You must have ffmpeg installed on your server for this to work
            command = [
                "ffmpeg", "-y", 
                "-f", "mulaw", 
                "-ar", "8000", 
                "-i", raw_filepath, 
                "-c:a", "aac", 
                final_m4a_filepath
            ]

            # Run the command and route both standard output and errors to the OS-appropriate black hole
            subprocess.run(
                command, 
                stdout=subprocess.DEVNULL, 
                stderr=subprocess.DEVNULL
            )

            file_link = upload_to_wasabi_and_get_link(
                local_file_path=final_m4a_filepath, 
                object_name=wasabi_object_name
            )

            if file_link:
                if not call_sid:
                    print("Call SID is missing.")
                    return
                with app.app_context():
                    db.session.query(CallRecord).filter_by(call_sid=call_sid).update({"recording_url": file_link})
                    db.session.commit()

                print(f"File uploaded to Wasabi. Accessible at: {file_link}")
            
            # 4. Save the hash to your Database
            # pseudo-code: db.execute("INSERT INTO recordings (call_id, hash) VALUES (?, ?)", (stream_sid, file_hash))
            print(f"Successfully processed and saved. Database Hash: {file_hash}")
            
        finally:
        # 5. Clean up local disk (delete both the raw file and the m4a once uploaded)
            if os.path.exists(raw_filepath):
                os.remove(raw_filepath)
            if os.path.exists(final_m4a_filepath):
                os.remove(final_m4a_filepath)
        
        # 1. Save raw bytes to a temp file (e.g., temp_raw.ulaw)
        
        # 2. Use FFmpeg (via command line or pydub) to convert:
        #    ffmpeg -f mulaw -ar 8000 -i temp_raw.ulaw -c:a aac output.m4a
        
        # 3. Upload output.m4a to AWS S3 using the boto3 library
        #    s3_url = upload_to_s3("output.m4a")
        
        # 4. Save s3_url to your Database
        #    db.execute("INSERT INTO calls (id, audio_link) VALUES (?, ?)", (stream_sid, s3_url))
        
        # 5. Clean up temp files
        print(f"Finished processing audio for {stream_sid}")


    @app.get("/health")
    def health():
        return jsonify({"status": "ok"})

    @app.get("/api/calls")
    def list_calls():
        records = CallRecord.query.order_by(CallRecord.id.desc()).all()
        return jsonify([record.to_dict() for record in records])
    
    @app.post("/api/twilio/voice")
    def twilio_voice():
        record = CallRecord.create_from_request(request.form)
        db.session.add(record)
        print(record.call_sid)
        db.session.commit()


        response = VoiceResponse()

        """
        response.say("Hi hier ist Thorsten, deine KI Telefonauskunft. Bitte beachte, KI's können Fehler machen. Wenn das Gepräch nicht aufgezeichnet werden soll, drücken Sie die 1. Was möchtest du wissen?",
                     voice="Google.de-DE-Chirp3-HD-Orus",
                    language="de-DE")
        """
        
        connect = Connect()
        stream = Stream(url=f"wss://{Config.SELF_URL}/audiostream/{record.call_sid}")
        connect.append(stream)
        response.append(connect)

        return str(response), 200, {"Content-Type": "application/xml"}
    
    @sock.route("/audiostream-test")
    def audiostream_test(ws):
        while True:
            data = ws.receive()
            #print("Received audio chunk of size:", len(data))

    @sock.route("/audiostream/<call_sid>")
    def audio_stream(ws, call_sid):
        """ Handles the active call, buffers audio, and forwards it. """
        print(call_sid)
        
        # 1. Create a buffer to hold the audio chunks in memory
        audio_buffer = bytearray()
        stream_sid = None
        
        # 2. Connect to your OTHER WebSockets server
        # Note: We use websocket.create_connection for a synchronous client
        destination_uri = Config.WEBSOCKET_URL
        try:
            dest_ws = websocket.create_connection(destination_uri)
            print("Connected to destination WebSocket server.")
        except Exception as e:
            print(f"Failed to connect to destination WSS: {e}")
            return # Abort if we can't reach the backend

        while True:
            # Receive message from Twilio
            message = ws.receive()
            
            if message is None:
                break
                
            data = json.loads(message)
            event = data.get("event")

            if event == "start":
                stream_sid = data["start"]["streamSid"]
                print(f"Call started. SID: {stream_sid}")

            elif event == "media":
                # Extract the base64 payload
                b64_payload = data["media"]["payload"]
                
                # --- THE TEE SPLIT ---
                
                # PATH A: Forward it immediately to the destination WSS
                # (Assuming the destination wants the raw base64 Twilio JSON payload)
                try:
                    dest_ws.send(message) 
                except Exception as e:
                    print(f"Error forwarding to destination: {e}")

                # PATH B: Log it to our local buffer
                raw_bytes = base64.b64decode(b64_payload)
                audio_buffer.extend(raw_bytes)

            elif event == "stop":
                print("Call ended by Twilio.")
                break

        # 3. THE CALL IS OVER
        # Close the forwarding connection
        dest_ws.close()
        
        # Kick off the background thread to handle FFmpeg and S3 upload
        # We pass a copy of the buffer so the thread has isolated data
        if len(audio_buffer) > 0:
            processing_thread = threading.Thread(
                target=process_and_upload_audio, 
                args=(audio_buffer.copy(), stream_sid, call_sid)
            )
            processing_thread.start()
    
    """
    @app.post("/api/twilio/voice/logging-rejected")
    def twilio_voice_logging_rejected():

        digit_pressed = request.values.get('Digits', None)
    
        response = VoiceResponse()
        
        # Check if the pressed digit is '1'
        if digit_pressed == '1':
            response.say(
                "Das Gespräch wird nicht aufgezeichnet.", 
                voice="Google.de-DE-Chirp3-HD-Orus", 
                language="de-DE"
            )
        else:
            # Fallback if they pressed a different key (like 2, 3, etc.)
            response.say("Das war nicht die Eins. Auf Wiedersehen.", language="de-DE")
            
        return str(response), 200, {"Content-Type": "application/xml"}
    """
    return app


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--drop-all",
        action="store_true",
        help="Drop and recreate all database tables on startup.",
    )
    args = parser.parse_args()

    application = create_app(drop_all=args.drop_all)
    application.run(host="0.0.0.0", port=5000, debug=True)
