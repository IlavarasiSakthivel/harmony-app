from flask import Blueprint, request, jsonify

from app.services.analytics_service import insights

bp = Blueprint("insights", __name__)


@bp.route("/insights", methods=["GET"])
def get_insights():
    days = request.args.get("days", 30, type=int)
    user_id = request.args.get("user_id", type=int)
    result = insights(days=days, user_id=user_id)
    return jsonify(result)
