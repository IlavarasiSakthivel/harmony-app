from flask import Blueprint, request, jsonify

from app.services.analytics_service import daily_stats

bp = Blueprint("stats", __name__)


@bp.route("/stats/daily", methods=["GET"])
def daily():
    date_str = request.args.get("date")
    if not date_str:
        return jsonify({"error": "Query param 'date' (YYYY-MM-DD) required"}), 400
    user_id = request.args.get("user_id", type=int)
    result = daily_stats(date_str, user_id=user_id)
    if result is None:
        return jsonify({"error": "Invalid date format (use YYYY-MM-DD)"}), 400
    return jsonify(result)
