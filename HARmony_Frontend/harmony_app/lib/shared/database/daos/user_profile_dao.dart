import 'package:floor/floor.dart';

import '../entities/user_profile_entity.dart';

@dao
abstract class UserProfileDao {
  @Query('SELECT * FROM UserProfileEntity LIMIT 1')
  Future<UserProfileEntity?> getProfile();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertProfile(UserProfileEntity profile);

  @Update()
  Future<void> updateProfile(UserProfileEntity profile);

  @Query('DELETE FROM UserProfileEntity')
  Future<void> deleteAll();
}
