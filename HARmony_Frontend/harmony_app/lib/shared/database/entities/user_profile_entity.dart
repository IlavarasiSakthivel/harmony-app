import 'package:floor/floor.dart';

@entity
class UserProfileEntity {
  @PrimaryKey(autoGenerate: true)
  final int? id;
  final int? age;
  final double? heightCm;
  final int dailyStepsGoal;
  final int dailyActiveMinutesGoal;
  final int updatedAtMs;

  UserProfileEntity({
    this.id,
    this.age,
    this.heightCm,
    this.dailyStepsGoal = 10000,
    this.dailyActiveMinutesGoal = 30,
    required this.updatedAtMs,
  });
}
