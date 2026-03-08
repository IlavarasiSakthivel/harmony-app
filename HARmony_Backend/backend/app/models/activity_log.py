from app import db


class ActivityLog(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    session_id = db.Column(db.Integer, db.ForeignKey("session.id"), nullable=False)
    timestamp = db.Column(db.DateTime, nullable=False)
    activity = db.Column(db.String(50), nullable=True)
    confidence = db.Column(db.Float, nullable=True)
    intensity = db.Column(db.String(20), nullable=True)  # LOW, MEDIUM, HIGH
