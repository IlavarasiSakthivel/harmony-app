import 'package:floor/floor.dart';

import '../entities/session_entity.dart';

@dao
abstract class SessionDao {
  @Query('SELECT * FROM SessionEntity ORDER BY startTimeMs DESC')
  Future<List<SessionEntity>> getAllSessions();

  @Query('SELECT * FROM SessionEntity WHERE startTimeMs >= :startMs AND startTimeMs < :endMs ORDER BY startTimeMs ASC')
  Future<List<SessionEntity>> getSessionsByDateRange(int startMs, int endMs);

  @Query('SELECT * FROM SessionEntity WHERE sessionId = :sessionId LIMIT 1')
  Future<SessionEntity?> getSessionBySessionId(String sessionId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertSession(SessionEntity session);

  @Query('DELETE FROM SessionEntity WHERE id = :id')
  Future<void> deleteById(int id);

  @Query('DELETE FROM SessionEntity')
  Future<void> deleteAll();
}
