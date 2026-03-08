import 'dart:async';

import 'daos/activity_log_dao.dart';
import 'daos/badge_dao.dart';
import 'daos/session_dao.dart';
import 'daos/user_profile_dao.dart';
import 'entities/activity_log_entity.dart';
import 'entities/badge_entity.dart';
import 'entities/session_entity.dart';
import 'entities/user_profile_entity.dart';

part 'app_database.g.dart';

/// Mock database implementation using in-memory storage
/// NOTE: Floor ORM code generation was disabled due to build compatibility issues
/// In production, either:
/// 1. Re-enable Floor with compatible generator version
/// 2. Replace with Hive or SQLite for persistent storage
/// 3. Use Riverpod providers with shared_preferences for simple cache
abstract class AppDatabase {
  SessionDao get sessionDao;
  ActivityLogDao get activityLogDao;
  UserProfileDao get userProfileDao;
  BadgeDao get badgeDao;

  static Future<AppDatabase> open() async {
    // Return a mock implementation for now
    return _MockAppDatabase();
  }
}

/// Mock implementation - replace with real database when Floor is re-enabled
class _MockAppDatabase extends AppDatabase {
  late final SessionDao _sessionDao = _MockSessionDao();
  late final ActivityLogDao _activityLogDao = _MockActivityLogDao();
  late final UserProfileDao _userProfileDao = _MockUserProfileDao();
  late final BadgeDao _badgeDao = _MockBadgeDao();

  @override
  SessionDao get sessionDao => _sessionDao;

  @override
  ActivityLogDao get activityLogDao => _activityLogDao;

  @override
  UserProfileDao get userProfileDao => _userProfileDao;

  @override
  BadgeDao get badgeDao => _badgeDao;
}

// Mock DAO implementations
// Mock DAO implementations
class _MockSessionDao implements SessionDao {
  final List<SessionEntity> _sessions = [];

  @override
  Future<void> insertSession(SessionEntity session) async {
    _sessions.add(session);
  }

  @override
  Future<List<SessionEntity>> getAllSessions() async {
    return _sessions;
  }

  @override
  Future<SessionEntity?> getSessionById(int id) async {
    try {
      return _sessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<SessionEntity?> getSessionBySessionId(String sessionId) async {
    try {
      return _sessions.firstWhere((s) => s.sessionId == sessionId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<SessionEntity>> getSessionsByDateRange(int startMs, int endMs) async {
    return _sessions.where((s) => s.startTimeMs >= startMs && s.startTimeMs < endMs).toList();
  }

  @override
  Future<void> updateSession(SessionEntity session) async {
    final index = _sessions.indexWhere((s) => s.sessionId == session.sessionId);
    if (index != -1) {
      _sessions[index] = session;
    }
  }

  @override
  Future<void> deleteSession(int id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> deleteById(int id) async {
    _sessions.removeWhere((s) => s.id == id);
  }

  @override
  Future<void> deleteAll() async {
    _sessions.clear();
  }
}

class _MockActivityLogDao implements ActivityLogDao {
  final List<ActivityLogEntity> _logs = [];

  @override
  Future<void> insertActivityLog(ActivityLogEntity log) async {
    _logs.add(log);
  }

  @override
  Future<void> insertLog(ActivityLogEntity log) async {
    _logs.add(log);
  }

  @override
  Future<void> insertLogs(List<ActivityLogEntity> logs) async {
    _logs.addAll(logs);
  }

  @override
  Future<List<ActivityLogEntity>> getActivityLogsBySession(int sessionId) async {
    return _logs.where((l) => l.sessionId == sessionId).toList();
  }

  @override
  Future<List<ActivityLogEntity>> getLogsBySessionId(int sessionId) async {
    return _logs.where((l) => l.sessionId == sessionId).toList();
  }

  @override
  Future<List<ActivityLogEntity>> getAllActivityLogs() async {
    return _logs;
  }

  @override
  Future<List<ActivityLogEntity>> getAllLogs() async {
    return _logs;
  }

  @override
  Future<void> deleteActivityLog(int id) async {
    _logs.removeWhere((l) => l.id == id);
  }

  @override
  Future<void> deleteBySessionId(int sessionId) async {
    _logs.removeWhere((l) => l.sessionId == sessionId);
  }

  @override
  Future<void> deleteAll() async {
    _logs.clear();
  }
}

class _MockUserProfileDao implements UserProfileDao {
  final List<UserProfileEntity> _profiles = [];

  @override
  Future<void> insertUserProfile(UserProfileEntity profile) async {
    _profiles.add(profile);
  }

  @override
  Future<void> insertProfile(UserProfileEntity profile) async {
    _profiles.add(profile);
  }

  @override
  Future<UserProfileEntity?> getUserProfile() async {
    return _profiles.isNotEmpty ? _profiles.first : null;
  }

  @override
  Future<UserProfileEntity?> getProfile() async {
    return _profiles.isNotEmpty ? _profiles.first : null;
  }

  @override
  Future<void> updateUserProfile(UserProfileEntity profile) async {
    if (_profiles.isNotEmpty) {
      _profiles[0] = profile;
    } else {
      _profiles.add(profile);
    }
  }

  @override
  Future<void> updateProfile(UserProfileEntity profile) async {
    if (_profiles.isNotEmpty) {
      _profiles[0] = profile;
    } else {
      _profiles.add(profile);
    }
  }

  @override
  Future<void> deleteAll() async {
    _profiles.clear();
  }
}

class _MockBadgeDao implements BadgeDao {
  final List<BadgeEntity> _badges = [];

  @override
  Future<void> insertBadge(BadgeEntity badge) async {
    _badges.add(badge);
  }

  @override
  Future<List<BadgeEntity>> getUserBadges(int userId) async {
    return _badges.where((b) => b.id == userId).toList();
  }

  @override
  Future<List<BadgeEntity>> getAllBadges() async {
    return _badges;
  }

  @override
  Future<BadgeEntity?> getBadgeById(String badgeId) async {
    try {
      return _badges.firstWhere((b) => b.badgeId == badgeId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> deleteBadge(int id) async {
    _badges.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteById(int id) async {
    _badges.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> deleteAll() async {
    _badges.clear();
  }
}
