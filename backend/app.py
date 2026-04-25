from datetime import datetime

from flask import Flask, jsonify, request

from config import Config
from backend.database import ensure_database_exists
from backend.models import CallRecord, db


def create_app() -> Flask:
    ensure_database_exists()

    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)

    with app.app_context():
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

    return app


if __name__ == "__main__":
    application = create_app()
    application.run(host="0.0.0.0", port=5000, debug=True)
