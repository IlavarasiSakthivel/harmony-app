import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/database/app_database.dart';
import 'package:harmony_app/shared/database/entities/session_entity.dart';
import 'package:harmony_app/shared/database/entities/activity_log_entity.dart';

class ActivityStorageService {
  final AppDatabase? _database;

  ActivityStorageService({AppDatabase? database}) : _database = database;

  static const String _sessionsKey = 'activity_sessions';
  static const String _settingsKey = 'app_settings';
  static const String _snapshotsKey = 'sensor_snapshots';
  static const String _coachAlertsKey = 'coach_alerts';

  /// Builds a CSV string from all sessions for export.
  Future<String> exportSessionsAsCsv() async {
    final sessions = await getAllSessions();
    final sb = StringBuffer();
    sb.writeln('Session ID,Start Time,End Time,Duration (min),Summary,Prediction Count');
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    for (final s in sessions) {
      sb.writeln('"${s.id}","${dateFormat.format(s.startTime)}","${dateFormat.format(s.endTime)}",${s.duration.inMinutes},"${s.summary ?? "Mixed"}",${s.predictions.length}');
    }
    sb.writeln();
    sb.writeln('Prediction Details (per session)');
    sb.writeln('Session ID,Activity,Confidence,Timestamp');
    for (final s in sessions) {
      for (final p in s.predictions) {
        sb.writeln('"${s.id}","${p.activity}",${p.confidence.toStringAsFixed(2)},"${dateFormat.format(p.timestamp)}"');
      }
    }
    return sb.toString();
  }

  Future<List<ActivitySession>> getAllSessions() async {
    if (_database != null) {
      final sessionEntities = await _database!.sessionDao.getAllSessions();
      final List<ActivitySession> sessions = [];

      for (final se in sessionEntities) {
        final logs = await _database!.activityLogDao.getLogsBySessionId(se.id ?? 0);
        sessions.add(ActivitySession(
          id: se.sessionId,
          startTime: DateTime.fromMillisecondsSinceEpoch(se.startTimeMs),
          endTime: DateTime.fromMillisecondsSinceEpoch(se.endTimeMs),
          summary: se.summary,
          predictions: logs
              .map((l) => ActivityPrediction(
                    activity: l.activity,
                    confidence: l.confidence,
                    timestamp: DateTime.fromMillisecondsSinceEpoch(l.timestampMs),
                  ))
              .toList(),
        ));
      }
      return sessions;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getStringList(_sessionsKey) ?? [];
    return sessionsJson.map((jsonString) => ActivitySession.fromJson(jsonDecode(jsonString))).toList();
  }

  Future<void> saveSession(ActivitySession session) async {
    if (_database != null) {
      final sessionEntity = SessionEntity(
        sessionId: session.id,
        startTimeMs: session.startTime.millisecondsSinceEpoch,
        endTimeMs: session.endTime.millisecondsSinceEpoch,
        summary: session.summary,
      );
      await _database!.sessionDao.insertSession(sessionEntity);
      
      // Get the inserted session to have its ID (though SessionDao.insertSession returns void in our definition)
      // Actually, we need the auto-generated ID for activity logs.
      // Let's modify SessionDao to return the inserted ID if possible, or just use sessionId if it's unique.
      // Looking at SessionDao, it returns Future<void>.
      // Let's query it back.
      final insertedSession = await _database!.sessionDao.getSessionBySessionId(session.id);
      if (insertedSession != null && insertedSession.id != null) {
        final logs = session.predictions.map((p) => ActivityLogEntity(
          sessionId: insertedSession.id!,
          activity: p.activity,
          confidence: p.confidence,
          timestampMs: p.timestamp.millisecondsSinceEpoch,
        )).toList();
        await _database!.activityLogDao.insertLogs(logs);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();
    sessions.add(session);
    final updatedSessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, updatedSessionsJson);
  }

  Future<void> deleteSession(String sessionId) async {
    if (_database != null) {
      final session = await _database!.sessionDao.getSessionBySessionId(sessionId);
      if (session != null && session.id != null) {
        await _database!.activityLogDao.deleteBySessionId(session.id!);
        await _database!.sessionDao.deleteById(session.id!);
      }
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final sessions = await getAllSessions();
    sessions.removeWhere((session) => session.id == sessionId);
    final updatedSessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, updatedSessionsJson);
  }

  Future<void> clearAllSessions() async {
    if (_database != null) {
      await _database!.activityLogDao.deleteAll();
      await _database!.sessionDao.deleteAll();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  // Settings methods (placeholder, can be expanded)
  Future<Map<String, dynamic>> getSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_settingsKey);
    return settingsJson != null ? jsonDecode(settingsJson) : {};
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings));
  }

  Future<void> updateSettings(Map<String, dynamic> updates) async {
    final current = await getSettings();
    current.addAll(updates);
    await saveSettings(current);
  }

  Future<List<Map<String, dynamic>>> getSensorSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_snapshotsKey) ?? [];
    return list.map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map)).toList();
  }

  Future<void> addSensorSnapshot(Map<String, dynamic> snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_snapshotsKey) ?? [];
    list.add(jsonEncode(snapshot));
    await prefs.setStringList(_snapshotsKey, list);
  }

  Future<void> clearSensorSnapshots() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_snapshotsKey);
  }

  Future<List<Map<String, dynamic>>> getCoachAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_coachAlertsKey) ?? [];
    return list.map((e) => Map<String, dynamic>.from(jsonDecode(e) as Map)).toList();
  }

  Future<void> addCoachAlert(Map<String, dynamic> alert) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_coachAlertsKey) ?? [];
    list.insert(0, jsonEncode(alert));
    await prefs.setStringList(_coachAlertsKey, list);
  }

  Future<void> clearCoachAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_coachAlertsKey);
  }
}
