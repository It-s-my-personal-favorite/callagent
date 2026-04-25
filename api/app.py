import argparse
from datetime import datetime
from pathlib import Path
import sys

from flask import Flask, jsonify, request
from twilio.twiml.voice_response import VoiceResponse


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


def create_app(drop_all: bool = False) -> Flask:
    ensure_database_exists()

    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    with app.app_context():
        if drop_all:
            db.drop_all()
        db.create_all()

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"})

    @app.post("/api/calls")
    def create_call():
        payload = request.get_json(silent=True) or {}

        required_fields = ["phone_number", "chat_date", "call_time"]
        missing_fields = [field for field in required_fields if field not in payload]
        if missing_fields:
            return (
                jsonify(
                    {
                        "error": "Missing required fields",
                        "missing": missing_fields,
                    }
                ),
                400,
            )

        try:
            chat_date = datetime.strptime(payload["chat_date"], "%Y-%m-%d").date()
        except ValueError:
            return (
                jsonify({"error": "chat_date must use format YYYY-MM-DD"}),
                400,
            )

        call_time_raw = payload["call_time"]
        parsed_call_time = None
        for fmt in ("%H:%M", "%H:%M:%S"):
            try:
                parsed_call_time = datetime.strptime(call_time_raw, fmt).time()
                break
            except ValueError:
                continue

        if parsed_call_time is None:
            return (
                jsonify({"error": "call_time must use format HH:MM or HH:MM:SS"}),
                400,
            )

        record = CallRecord(
            phone_number=str(payload["phone_number"]),
            chat_date=chat_date,
            call_time=parsed_call_time,
        )
        db.session.add(record)
        db.session.commit()

        return jsonify(record.to_dict()), 201

    @app.get("/api/calls")
    def list_calls():
        records = CallRecord.query.order_by(CallRecord.id.desc()).all()
        return jsonify([record.to_dict() for record in records])
    
    @app.post("/api/twilio/voice")
    def twilio_voice():
        CallRecord.create_from_request(request.form)
        response = VoiceResponse()

        gather = response.gather(
            num_digits=1,
            action="/api/twilio/voice/logging-rejected",
            method="POST",
        )

        gather.say("Hallo, hier ist CallAgent, deine KI Telefonauskunft. Bitte beachte, KI's können Fehler machen. Wenn das Gepräch nicht aufgezeichnet werden soll, drücken Sie die 1. Was möchtest du wissen?",
                     voice="Google.de-DE-Chirp3-HD-Orus",
                    language="de-DE")
        
        response.append(gather)
        

        return str(response), 200, {"Content-Type": "application/xml"}
    
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
