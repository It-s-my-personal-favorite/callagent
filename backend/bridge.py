import asyncio
import websockets
import json
import base64
import os

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

OPENAI_WS_URL = "wss://api.openai.com/v1/realtime?model=gpt-4o-realtime-preview"

async def handle_twilio(ws, path):
    print("Twilio connected")

    async with websockets.connect(
        OPENAI_WS_URL,
        extra_headers={
            "Authorization": f"Bearer {OPENAI_API_KEY}",
            "OpenAI-Beta": "realtime=v1"
        }
    ) as openai_ws:

        async def receive_from_twilio():
            async for message in ws:
                data = json.loads(message)

                if data["event"] == "media":
                    audio_payload = data["media"]["payload"]

                    await openai_ws.send(json.dumps({
                        "type": "input_audio_buffer.append",
                        "audio": audio_payload
                    }))

                elif data["event"] == "start":
                    print("Stream started")

        async def send_to_twilio():
            async for message in openai_ws:
                response = json.loads(message)

                if response["type"] == "response.audio.delta":
                    await ws.send(json.dumps({
                        "event": "media",
                        "media": {
                            "payload": response["delta"]
                        }
                    }))

        await asyncio.gather(receive_from_twilio(), send_to_twilio())

async def main():
    server = await websockets.serve(handle_twilio, "0.0.0.0", 8765)
    print("Bridge server running on ws://localhost:8765")
    await asyncio.Future()

asyncio.run(main())