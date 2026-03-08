import 'package:floor/floor.dart';

@entity
class SessionEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String sessionId;
  final int startTimeMs;
  final int endTimeMs;
  final String? summary;

  SessionEntity({
    this.id,
    required this.sessionId,
    required this.startTimeMs,
    required this.endTimeMs,
    this.summary,
  });
}
