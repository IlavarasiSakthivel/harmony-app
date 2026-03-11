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

  /// Builds a PDF-friendly text report from all sessions (can be converted to PDF with a library)
  Future<String> exportSessionsAsPdfReport() async {
    final sessions = await getAllSessions();
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final sb = StringBuffer();
    
    final reportDate = DateTime.now();
    sb.writeln('═' * 80);
    sb.writeln('HARmony Activity Recognition - Comprehensive Report');
    sb.writeln('Generated: ${dateFormat.format(reportDate)}');
    sb.writeln('═' * 80);
    sb.writeln('');
    
    // Overall Statistics
    sb.writeln('OVERALL STATISTICS');
    sb.writeln('─' * 80);
    sb.writeln('Total Sessions: ${sessions.length}');
    
    final totalDuration = sessions.fold<Duration>(Duration.zero, (sum, s) => sum + s.duration);
    sb.writeln('Total Activity Duration: ${totalDuration.inHours}h ${totalDuration.inMinutes % 60}m');
    
    final totalPredictions = sessions.fold<int>(0, (sum, s) => sum + s.predictions.length);
    sb.writeln('Total Predictions: $totalPredictions');
    
    // Activity Distribution
    final activityCounts = <String, int>{};
    for (final session in sessions) {
      for (final pred in session.predictions) {
        activityCounts[pred.activity] = (activityCounts[pred.activity] ?? 0) + 1;
      }
    }
    
    sb.writeln('');
    sb.writeln('ACTIVITY DISTRIBUTION');
    sb.writeln('─' * 80);
    for (final entry in activityCounts.entries) {
      final percentage = totalPredictions > 0 ? (entry.value / totalPredictions * 100) : 0;
      sb.writeln('${entry.key.padRight(20)} ${entry.value.toString().padLeft(5)} predictions (${percentage.toStringAsFixed(1)}%)');
    }
    
    sb.writeln('');
    sb.writeln('DETAILED SESSION REPORTS');
    sb.writeln('═' * 80);
    
    for (int i = 0; i < sessions.length; i++) {
      final session = sessions[i];
      sb.writeln('');
      sb.writeln('Session ${i + 1}: ${session.summary ?? "Mixed Activities"}');
      sb.writeln('─' * 80);
      sb.writeln('Session ID: ${session.id}');
      sb.writeln('Start Time: ${dateFormat.format(session.startTime)}');
      sb.writeln('End Time: ${dateFormat.format(session.endTime)}');
      sb.writeln('Duration: ${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s');
      sb.writeln('Predictions: ${session.predictions.length}');
      sb.writeln('');
      
      if (session.predictions.isNotEmpty) {
        sb.writeln('Activity Timeline:');
        double avgConfidence = session.predictions.fold(0.0, (sum, p) => sum + p.confidence) / session.predictions.length;
        sb.writeln('Average Confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
        
        // Show first, middle, and last predictions as samples
        if (session.predictions.length <= 5) {
          for (final pred in session.predictions) {
            sb.writeln('  • ${dateFormat.format(pred.timestamp)} - ${pred.activity} (${(pred.confidence * 100).toStringAsFixed(0)}%)');
          }
        } else {
          // Show first 2, skipped middle, last 2
          for (int j = 0; j < 2; j++) {
            final pred = session.predictions[j];
            sb.writeln('  • ${dateFormat.format(pred.timestamp)} - ${pred.activity} (${(pred.confidence * 100).toStringAsFixed(0)}%)');
          }
          sb.writeln('  ... [${session.predictions.length - 4} more predictions] ...');
          for (int j = session.predictions.length - 2; j < session.predictions.length; j++) {
            final pred = session.predictions[j];
            sb.writeln('  • ${dateFormat.format(pred.timestamp)} - ${pred.activity} (${(pred.confidence * 100).toStringAsFixed(0)}%)');
          }
        }
      }
      sb.writeln('');
    }
    
    sb.writeln('═' * 80);
    sb.writeln('End of Report');
    sb.writeln('═' * 80);
    
    return sb.toString();
  }

  /// Export a single session as PDF-friendly text report
  Future<String> exportSessionAsPdfReport(String sessionId) async {
    final sessions = await getAllSessions();
    final session = sessions.firstWhere((s) => s.id == sessionId, orElse: () => ActivitySession(
      id: '',
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      predictions: [],
    ));
    
    if (session.id.isEmpty) {
      throw Exception('Session not found: $sessionId');
    }
    
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final sb = StringBuffer();
    
    sb.writeln('═' * 80);
    sb.writeln('HARmony Activity Recognition - Session Report');
    sb.writeln('═' * 80);
    sb.writeln('');
    sb.writeln('SESSION DETAILS');
    sb.writeln('─' * 80);
    sb.writeln('Session ID: ${session.id}');
    sb.writeln('Activity Type: ${session.summary ?? "Mixed"}');
    sb.writeln('Start Time: ${dateFormat.format(session.startTime)}');
    sb.writeln('End Time: ${dateFormat.format(session.endTime)}');
    sb.writeln('Duration: ${session.duration.inMinutes}m ${session.duration.inSeconds % 60}s');
    sb.writeln('Total Predictions: ${session.predictions.length}');
    
    if (session.predictions.isNotEmpty) {
      sb.writeln('');
      sb.writeln('STATISTICS');
      sb.writeln('─' * 80);
      
      double avgConfidence = session.predictions.fold(0.0, (sum, p) => sum + p.confidence) / session.predictions.length;
      sb.writeln('Average Confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
      
      double maxConfidence = session.predictions.map((p) => p.confidence).reduce((a, b) => a > b ? a : b);
      sb.writeln('Max Confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%');
      
      double minConfidence = session.predictions.map((p) => p.confidence).reduce((a, b) => a < b ? a : b);
      sb.writeln('Min Confidence: ${(minConfidence * 100).toStringAsFixed(1)}%');
      
      // Activity breakdown
      final activityCounts = <String, int>{};
      for (final pred in session.predictions) {
        activityCounts[pred.activity] = (activityCounts[pred.activity] ?? 0) + 1;
      }
      
      sb.writeln('');
      sb.writeln('Activity Distribution:');
      for (final entry in activityCounts.entries) {
        final percentage = (entry.value / session.predictions.length * 100);
        sb.writeln('  ${entry.key.padRight(20)} ${entry.value.toString().padLeft(5)} (${percentage.toStringAsFixed(1)}%)');
      }
      
      sb.writeln('');
      sb.writeln('PREDICTION TIMELINE');
      sb.writeln('─' * 80);
      
      for (int i = 0; i < session.predictions.length; i++) {
        final pred = session.predictions[i];
        final timeOffset = pred.timestamp.difference(session.startTime);
        sb.writeln('[${timeOffset.inSeconds}s] ${pred.activity.padRight(20)} ${(pred.confidence * 100).toStringAsFixed(1)}%');
      }
    }
    
    sb.writeln('');
    sb.writeln('═' * 80);
    sb.writeln('Generated: ${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}');
    sb.writeln('═' * 80);
    
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
