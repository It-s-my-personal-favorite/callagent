import pyaudio
import wave
import io
from google import genai
from google.genai import types

# 1. Setup Client (Using europe-west3 for EU compliance/stability)
client = genai.Client(
    vertexai=True, 
    project="hackathon-kassel", 
    location="europe-west3"
)

# STABLE MODEL ID for April 2026
MODEL_ID = "gemini-2.5-flash"

def record_and_ask():
    # Audio settings
    p = pyaudio.PyAudio()
    stream = p.open(format=pyaudio.paInt16, channels=1, rate=16000, 
                    input=True, frames_per_buffer=1024)
    
    print("\n🎤 [LISTENING] Speak now (4 seconds)...")
    frames = []
    for _ in range(0, int(16000 / 1024 * 4)):
        frames.append(stream.read(1024))
    
    print("🧠 [THINKING] Processing audio...")
    stream.stop_stream(); stream.close(); p.terminate()
    
    # Wrap in WAV format for the API
    buf = io.BytesIO()
    with wave.open(buf, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(p.get_sample_size(pyaudio.paInt16))
        wf.setframerate(16000)
        wf.writeframes(b''.join(frames))

    # 2. Send as a standard turn-based request
    try:
        response = client.models.generate_content(
            model=MODEL_ID,
            contents=[
                "Answer the user's question based on this audio clip.",
                types.Part.from_bytes(data=buf.getvalue(), mime_type="audio/wav")
            ]
        )
        print(f"🤖 AI: {response.text}")
    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    while True:
        record_and_ask()
        if input("\nPress Enter to talk again (or 'q' to quit): ").lower() == 'q':
            break