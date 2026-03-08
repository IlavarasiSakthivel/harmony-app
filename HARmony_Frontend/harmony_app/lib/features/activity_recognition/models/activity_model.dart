import 'package:json_annotation/json_annotation.dart';

part 'activity_model.g.dart';

@JsonSerializable()
class ActivityModel {
  final String activity; // e.g., 'walking', 'running', 'sitting'
  final double confidence; // Confidence score for the predicted activity
  final int timestamp; // Timestamp of the prediction

  ActivityModel({
    required this.activity,
    required this.confidence,
    required this.timestamp,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) => _$ActivityModelFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityModelToJson(this);
}

@JsonSerializable()
class ActivityPrediction {
  final String activity;
  final double confidence;
  final DateTime timestamp;

  ActivityPrediction({
    required this.activity,
    required this.confidence,
    required this.timestamp,
  });

  factory ActivityPrediction.fromJson(Map<String, dynamic> json) => _$ActivityPredictionFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityPredictionToJson(this);
}

@JsonSerializable()
class ActivitySession {
  final String id;
  final DateTime startTime;
  final DateTime endTime;
  final List<ActivityPrediction> predictions;
  final String? summary;

  ActivitySession({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.predictions,
    this.summary,
  });

  Duration get duration => endTime.difference(startTime);

  factory ActivitySession.fromJson(Map<String, dynamic> json) => _$ActivitySessionFromJson(json);
  Map<String, dynamic> toJson() => _$ActivitySessionToJson(this);
}
