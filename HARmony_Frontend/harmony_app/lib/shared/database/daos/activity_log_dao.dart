import 'package:floor/floor.dart';

import '../entities/activity_log_entity.dart';

@dao
abstract class ActivityLogDao {
  @Query('SELECT * FROM ActivityLogEntity WHERE sessionId = :sessionId ORDER BY timestampMs ASC')
  Future<List<ActivityLogEntity>> getLogsBySessionId(int sessionId);

  @Query('SELECT * FROM ActivityLogEntity ORDER BY timestampMs DESC')
  Future<List<ActivityLogEntity>> getAllLogs();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLog(ActivityLogEntity log);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertLogs(List<ActivityLogEntity> logs);

  @Query('DELETE FROM ActivityLogEntity WHERE sessionId = :sessionId')
  Future<void> deleteBySessionId(int sessionId);

  @Query('DELETE FROM ActivityLogEntity')
  Future<void> deleteAll();
}
