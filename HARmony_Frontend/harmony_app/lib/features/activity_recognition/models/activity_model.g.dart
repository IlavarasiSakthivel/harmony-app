// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) =>
    ActivityModel(
      activity: json['activity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
    );

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'activity': instance.activity,
      'confidence': instance.confidence,
      'timestamp': instance.timestamp,
    };

ActivityPrediction _$ActivityPredictionFromJson(Map<String, dynamic> json) =>
    ActivityPrediction(
      activity: json['activity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

Map<String, dynamic> _$ActivityPredictionToJson(ActivityPrediction instance) =>
    <String, dynamic>{
      'activity': instance.activity,
      'confidence': instance.confidence,
      'timestamp': instance.timestamp.toIso8601String(),
    };

ActivitySession _$ActivitySessionFromJson(Map<String, dynamic> json) =>
    ActivitySession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      predictions: (json['predictions'] as List<dynamic>)
          .map((e) => ActivityPrediction.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] as String?,
    );

Map<String, dynamic> _$ActivitySessionToJson(ActivitySession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'predictions': instance.predictions,
      'summary': instance.summary,
    };
