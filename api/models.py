from datetime import datetime
import enum
from flask_sqlalchemy import SQLAlchemy
from flask import Request


db = SQLAlchemy()

class CallStatus(enum.Enum):
    ACTIVE = 1
    COMPLETED = 2
    CANCELLED = 3
    UNKNOWN = 4

class CallDevice(enum.Enum):
    MOBILE = 1
    LANDLINE = 2
    VOIP = 3

class CallRecord(db.Model):
    __tablename__ = "call_records"

    id = db.Column(db.Integer, primary_key=True)
    call_sid = db.Column(db.String(34), nullable=False, unique=True, index=True)
    
    from_phone_number = db.Column(db.String(32), nullable=False, index=True)
    to_phone_number = db.Column(db.String(32), nullable=False, index=True)

    call_start = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)
    call_end = db.Column(db.DateTime, nullable=True)

    cost_micro_cents = db.Column(db.Integer, nullable=True, default=0)
    status = db.Column(db.Enum(CallStatus), nullable=False, default=CallStatus.ACTIVE)
    device = db.Column(db.Enum(CallDevice), nullable=False, default=CallDevice.MOBILE)

    recording_url = db.Column(db.String(300), nullable=True)

    @staticmethod
    def create_from_request(form: Request):
        record = CallRecord(
            call_sid=form.get("CallSid", ""),
            from_phone_number=form.get("From", ""),
            to_phone_number=form.get("To", ""),
            call_start=datetime.utcnow(),
            status=CallStatus.ACTIVE,
            device=CallDevice.MOBILE,
        )

        # Debug output to verify incoming data
        for i in form.keys():
            print(f"{i}: {form[i]}")
        print("----")

        return record

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "call_sid": self.call_sid,
            "from_phone_number": self.from_phone_number,
            "to_phone_number": self.to_phone_number,
            "call_start": self.call_start.isoformat() if self.call_start else None,
            "call_end": self.call_end.isoformat() if self.call_end else None,
            "cost_micro_cents": self.cost_micro_cents,
            "status": self.status.name,
            "device": self.device.name,
            "recording_url": self.recording_url,
        }
