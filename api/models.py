from datetime import datetime

from flask_sqlalchemy import SQLAlchemy


db = SQLAlchemy()


class CallRecord(db.Model):
    __tablename__ = "call_records"

    id = db.Column(db.Integer, primary_key=True)
    phone_number = db.Column(db.String(32), nullable=False, index=True)
    chat_date = db.Column(db.Date, nullable=False)
    call_time = db.Column(db.Time, nullable=False)
    created_at = db.Column(db.DateTime, nullable=False, default=datetime.utcnow)

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "phone_number": self.phone_number,
            "chat_date": self.chat_date.isoformat(),
            "call_time": self.call_time.strftime("%H:%M:%S"),
            "created_at": self.created_at.isoformat(),
        }
