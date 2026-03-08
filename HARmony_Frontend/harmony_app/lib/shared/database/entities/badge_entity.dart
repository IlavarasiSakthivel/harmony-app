import 'package:floor/floor.dart';

@entity
class BadgeEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final String badgeId;
  final String name;
  final int earnedAtMs;
  final String? metadata;

  BadgeEntity({
    this.id,
    required this.badgeId,
    required this.name,
    required this.earnedAtMs,
    this.metadata,
  });
}
