from app import db


class Session(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("user.id"), nullable=True)
    start_time = db.Column(db.DateTime, nullable=False)
    end_time = db.Column(db.DateTime, nullable=True)
    total_duration = db.Column(db.Integer, nullable=True)  # seconds
    steps_estimate = db.Column(db.Integer, nullable=True)
    activity_breakdown = db.Column(db.JSON, nullable=True)  # {"WALKING": 1200, "SITTING": 600}
    average_confidence = db.Column(db.Float, nullable=True)

    activity_logs = db.relationship("ActivityLog", backref="session", lazy="dynamic", cascade="all, delete-orphan")
