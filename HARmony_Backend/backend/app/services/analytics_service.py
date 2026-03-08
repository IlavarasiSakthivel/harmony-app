"""
Daily stats, insights, and aggregations from sessions and activity logs.
"""
from datetime import datetime, timedelta

from app import db
from app.models import Session, ActivityLog
from app.config.constants import get_energy_level


def daily_stats(date_str, user_id=None):
    """
    date_str: YYYY-MM-DD
    Returns dict: date, activity_score, active_minutes, inactive_minutes, steps_estimate,
                  movement_intensity_distribution, energy_level.
    """
    try:
        day = datetime.strptime(date_str, "%Y-%m-%d").date()
    except ValueError:
        return None
    start = datetime.combine(day, datetime.min.time())
    end = start + timedelta(days=1)

    q = Session.query.filter(
        Session.start_time >= start,
        Session.start_time < end,
    )
    if user_id is not None:
        q = q.filter(Session.user_id == user_id)
    sessions = q.all()

    total_duration = sum(s.total_duration or 0 for s in sessions)
    steps = sum(s.steps_estimate or 0 for s in sessions)
    # Treat all session time as "active" for simplicity; inactive = 24*60 - active
    active_minutes = total_duration // 60
    inactive_minutes = max(0, 24 * 60 - active_minutes)
    # Simple score 0–100
    activity_score = min(100, (active_minutes / (24 * 60)) * 100 * 2)
    intensity_dist = {"LOW": 0, "MEDIUM": 0, "HIGH": 0}
    for s in sessions:
        if s.activity_breakdown:
            for act, secs in s.activity_breakdown.items():
                from app.config.constants import get_intensity_for_activity
                intensity_dist[get_intensity_for_activity(act)] = (
                    intensity_dist.get(get_intensity_for_activity(act), 0) + (secs // 60)
                )

    return {
        "date": date_str,
        "activity_score": round(activity_score, 1),
        "active_minutes": int(active_minutes),
        "inactive_minutes": int(inactive_minutes),
        "steps_estimate": int(steps),
        "movement_intensity_distribution": intensity_dist,
        "energy_level": get_energy_level(active_minutes),
    }


def insights(days=30, user_id=None):
    """
    Returns most active time/day, trend, anomalies, and textual insights.
    """
    since = datetime.utcnow() - timedelta(days=int(days))
    q = Session.query.filter(Session.start_time >= since)
    if user_id is not None:
        q = q.filter(Session.user_id == user_id)
    sessions = q.all()

    if not sessions:
        return {
            "most_active_day": None,
            "most_active_hour": None,
            "trend": "stable",
            "anomalies": [],
            "insights": ["No session data in the selected period."],
        }

    # By weekday
    by_weekday = {}
    for s in sessions:
        wd = s.start_time.strftime("%A")
        by_weekday[wd] = by_weekday.get(wd, 0) + (s.total_duration or 0)
    most_active_day = max(by_weekday, key=by_weekday.get) if by_weekday else None

    # By hour
    by_hour = {}
    for s in sessions:
        h = s.start_time.hour
        by_hour[h] = by_hour.get(h, 0) + (s.total_duration or 0)
    most_active_hour = max(by_hour, key=by_hour.get) if by_hour else None

    # Simple trend: compare first half vs second half of period
    mid = since + timedelta(days=int(days) / 2)
    first_half = sum(s.total_duration or 0 for s in sessions if s.start_time < mid)
    second_half = sum(s.total_duration or 0 for s in sessions if s.start_time >= mid)
    if second_half > first_half * 1.1:
        trend = "improving"
    elif second_half < first_half * 0.9:
        trend = "declining"
    else:
        trend = "stable"

    # Anomalies: sessions with very high or low duration vs average
    avg_dur = sum(s.total_duration or 0 for s in sessions) / len(sessions)
    anomalies = []
    for s in sessions:
        d = s.total_duration or 0
        if d > avg_dur * 2 or (avg_dur > 60 and d < avg_dur * 0.3):
            anomalies.append({
                "session_id": s.id,
                "date": s.start_time.date().isoformat(),
                "duration_seconds": d,
                "reason": "high" if d > avg_dur * 2 else "low",
            })

    insights_list = []
    if most_active_day:
        insights_list.append(f"You are most active on {most_active_day}s.")
    if most_active_hour is not None:
        insights_list.append(f"Peak activity hour: {most_active_hour}:00.")
    if by_weekday and len(by_weekday) >= 2:
        wk = sum(by_weekday.get(d, 0) for d in ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"])
        we = sum(by_weekday.get(d, 0) for d in ["Saturday", "Sunday"])
        if wk > 0 and we > 0:
            pct = int(100 * (wk - we) / max(wk, we))
            if abs(pct) > 20:
                insights_list.append(
                    f"You are {abs(pct)}% more active on {'weekdays' if pct > 0 else 'weekends'}."
                )

    return {
        "most_active_day": most_active_day,
        "most_active_hour": most_active_hour,
        "trend": trend,
        "anomalies": anomalies[:10],
        "insights": insights_list or ["Add more sessions to get personalized insights."],
    }
