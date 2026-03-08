import 'package:floor/floor.dart';

import '../entities/badge_entity.dart';

@dao
abstract class BadgeDao {
  @Query('SELECT * FROM BadgeEntity ORDER BY earnedAtMs DESC')
  Future<List<BadgeEntity>> getAllBadges();

  @Query('SELECT * FROM BadgeEntity WHERE badgeId = :badgeId LIMIT 1')
  Future<BadgeEntity?> getBadgeById(String badgeId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBadge(BadgeEntity badge);

  @Query('DELETE FROM BadgeEntity WHERE id = :id')
  Future<void> deleteById(int id);

  @Query('DELETE FROM BadgeEntity')
  Future<void> deleteAll();
}
