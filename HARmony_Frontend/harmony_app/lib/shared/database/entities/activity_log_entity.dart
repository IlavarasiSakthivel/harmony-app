import 'package:floor/floor.dart';

@entity
class ActivityLogEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int sessionId;
  final String activity;
  final double confidence;
  final int timestampMs;

  ActivityLogEntity({
    this.id,
    required this.sessionId,
    required this.activity,
    required this.confidence,
    required this.timestampMs,
  });
}
