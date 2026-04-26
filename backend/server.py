import os
import json
import base64
import asyncio
import tempfile

from fastapi import FastAPI, WebSocket
from fastapi.responses import Response
from twilio.twiml.voice_response import VoiceResponse, Start, Stream

from openai import OpenAI

app = FastAPI()
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# -----------------------------
# Twilio webhook
# -----------------------------
@app.post("/voice")
async def voice():
    response = VoiceResponse()

    start = Start()
    stream = Stream(url="wss://geometric-fiber-poncho.ngrok-free.dev/ws")
    start.append(stream)

    response.append(start)
    response.say("You are now connected to the AI assistant.")

    return Response(content=str(response), media_type="text/xml")


# -----------------------------
# WebSocket endpoint
# -----------------------------
@app.websocket("/ws")
async def websocket_endpoint(ws: WebSocket):
    await ws.accept()

    audio_buffer = b""

    async def process_audio():
        nonlocal audio_buffer

        while True:
            await asyncio.sleep(2)  # process every 2 seconds

            if len(audio_buffer) < 8000:
                continue

            try:
                # Save temp audio file
                with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as f:
                    f.write(audio_buffer)
                    temp_path = f.name

                audio_buffer = b""  # reset buffer

                # -------------------------
                # 1. Speech → Text
                # -------------------------
                with open(temp_path, "rb") as audio_file:
                    transcript = client.audio.transcriptions.create(
                        model="gpt-4o-mini-transcribe",
                        file=audio_file
                    )

                user_text = transcript.text
                print("User:", user_text)

                # -------------------------
                # 2. GPT response
                # -------------------------
                response = client.responses.create(
                    model="gpt-4.1",
                    input=user_text
                )

                reply = response.output[0].content[0].text
                print("AI:", reply)

                # -------------------------
                # 3. Text → Speech
                # -------------------------
                speech = client.audio.speech.create(
                    model="gpt-4o-mini-tts",
                    voice="alloy",
                    input=reply
                )

                audio_bytes = speech.read()

                # -------------------------
                # 4. Send back to Twilio
                # -------------------------
                encoded_audio = base64.b64encode(audio_bytes).decode("utf-8")

                await ws.send_json({
                    "event": "media",
                    "media": {
                        "payload": encoded_audio
                    }
                })

            except Exception as e:
                print("ERROR:", e)

    async def receive_audio():
        nonlocal audio_buffer

        while True:
            data = await ws.receive_json()

            if data["event"] == "media":
                chunk = base64.b64decode(data["media"]["payload"])
                audio_buffer += chunk

    await asyncio.gather(receive_audio(), process_audio())