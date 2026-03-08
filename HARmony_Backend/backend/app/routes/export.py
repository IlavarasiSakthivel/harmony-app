from flask import Blueprint, request, send_file
import io
import csv
from datetime import datetime

from app.models import Session, ActivityLog

bp = Blueprint("export", __name__)


@bp.route("/export/csv", methods=["GET"])
def export_csv():
    from_str = request.args.get("from")
    to_str = request.args.get("to")
    if not from_str or not to_str:
        return {"error": "Query params 'from' and 'to' (YYYY-MM-DD) required"}, 400
    try:
        start = datetime.strptime(from_str, "%Y-%m-%d")
        end = datetime.strptime(to_str, "%Y-%m-%d")
        end = end.replace(hour=23, minute=59, second=59, microsecond=999999)
    except ValueError:
        return {"error": "Invalid date format (use YYYY-MM-DD)"}, 400

    user_id = request.args.get("user_id", type=int)
    q = Session.query.filter(
        Session.start_time >= start,
        Session.start_time <= end,
    )
    if user_id is not None:
        q = q.filter(Session.user_id == user_id)
    sessions = q.all()

    output = io.StringIO()
    writer = csv.writer(output)
    writer.writerow(["Date", "Time", "Activity", "Confidence", "Duration", "Intensity"])
    for s in sessions:
        date_str = s.start_time.strftime("%Y-%m-%d") if s.start_time else ""
        time_str = s.start_time.strftime("%H:%M:%S") if s.start_time else ""
        # Session-level row
        first_activity = next(iter(s.activity_breakdown.keys()), "") if s.activity_breakdown else ""
        writer.writerow([
            date_str,
            time_str,
            first_activity,
            s.average_confidence or "",
            s.total_duration or "",
            "",
        ])
        for log in s.activity_logs:
            writer.writerow([
                log.timestamp.strftime("%Y-%m-%d") if log.timestamp else "",
                log.timestamp.strftime("%H:%M:%S") if log.timestamp else "",
                log.activity or "",
                log.confidence or "",
                "",
                log.intensity or "",
            ])

    output.seek(0)
    return send_file(
        io.BytesIO(output.getvalue().encode("utf-8")),
        mimetype="text/csv",
        as_attachment=True,
        download_name=f"harmony_export_{from_str}_{to_str}.csv",
    )
