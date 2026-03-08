from flask import Blueprint, request, jsonify

from app import db
from app.models import Session, ActivityLog

bp = Blueprint("sessions", __name__)


def _session_to_dict(s, with_logs=False):
    d = {
        "id": s.id,
        "user_id": s.user_id,
        "start_time": s.start_time.isoformat() if s.start_time else None,
        "end_time": s.end_time.isoformat() if s.end_time else None,
        "total_duration": s.total_duration,
        "steps_estimate": s.steps_estimate,
        "activity_breakdown": s.activity_breakdown,
        "average_confidence": s.average_confidence,
    }
    if with_logs:
        d["activity_logs"] = [
            {
                "id": log.id,
                "timestamp": log.timestamp.isoformat() if log.timestamp else None,
                "activity": log.activity,
                "confidence": log.confidence,
                "intensity": log.intensity,
            }
            for log in s.activity_logs
        ]
    return d


@bp.route("/sessions", methods=["POST"])
def create_session():
    data = request.get_json() or {}
    from datetime import datetime
    start_time = data.get("start_time")
    end_time = data.get("end_time")
    if not start_time:
        return jsonify({"error": "start_time required"}), 400
    try:
        st = datetime.fromisoformat(start_time.replace("Z", "+00:00"))
    except Exception:
        return jsonify({"error": "Invalid start_time"}), 400
    et = None
    if end_time:
        try:
            et = datetime.fromisoformat(end_time.replace("Z", "+00:00"))
        except Exception:
            pass
    total_duration = data.get("total_duration", 0)
    steps_estimate = data.get("steps_estimate")
    activity_breakdown = data.get("activity_breakdown")
    average_confidence = data.get("average_confidence")
    user_id = data.get("user_id")

    s = Session(
        user_id=user_id,
        start_time=st,
        end_time=et,
        total_duration=total_duration,
        steps_estimate=steps_estimate,
        activity_breakdown=activity_breakdown,
        average_confidence=average_confidence,
    )
    db.session.add(s)
    db.session.commit()
    return jsonify(_session_to_dict(s)), 201


@bp.route("/sessions", methods=["GET"])
def list_sessions():
    user_id = request.args.get("user_id", type=int)
    q = Session.query.order_by(Session.start_time.desc())
    if user_id is not None:
        q = q.filter(Session.user_id == user_id)
    page = request.args.get("page", 1, type=int)
    per_page = min(request.args.get("per_page", 20, type=int), 100)
    pagination = q.paginate(page=page, per_page=per_page, error_out=False)
    return jsonify({
        "sessions": [_session_to_dict(s) for s in pagination.items],
        "total": pagination.total,
        "page": page,
        "per_page": per_page,
    })


@bp.route("/sessions/<int:session_id>", methods=["GET"])
def get_session(session_id):
    s = Session.query.get(session_id)
    if not s:
        return jsonify({"error": "Session not found"}), 404
    return jsonify(_session_to_dict(s, with_logs=True))


@bp.route("/sessions/<int:session_id>", methods=["DELETE"])
def delete_session(session_id):
    s = Session.query.get(session_id)
    if not s:
        return jsonify({"error": "Session not found"}), 404
    db.session.delete(s)
    db.session.commit()
    return "", 204
