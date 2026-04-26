from flask import Flask, Response
from twilio.twiml.voice_response import VoiceResponse, Start, Stream

app = Flask(__name__)

@app.route("/voice", methods=["POST"])
def voice():
    response = VoiceResponse()

    start = Start()
    stream = Stream(url="wss://geometric-fiber-poncho.ngrok-free.dev/ws")  # your websocket endpoint
    start.append(stream)

    response.append(start)
    response.say("You are now connected to the AI assistant.")

    return Response(str(response), mimetype="text/xml")

if __name__ == "__main__":
    app.run(port=5000)