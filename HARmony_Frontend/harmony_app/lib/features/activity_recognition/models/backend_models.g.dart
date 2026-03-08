// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backend_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HealthCheckResponse _$HealthCheckResponseFromJson(Map<String, dynamic> json) =>
    HealthCheckResponse(
      status: json['status'] as String,
      modelLoaded: json['model_loaded'] as bool,
      modelName: json['model_name'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$HealthCheckResponseToJson(
  HealthCheckResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'model_loaded': instance.modelLoaded,
  'model_name': instance.modelName,
  'message': instance.message,
};

ModelInfoResponse _$ModelInfoResponseFromJson(Map<String, dynamic> json) =>
    ModelInfoResponse(
      modelName: json['model_name'] as String,
      inputShape: (json['input_shape'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      activityLabels: (json['activity_labels'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      description: json['description'] as String?,
      version: json['version'] as String?,
      expectedFeatures: (json['expected_features'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ModelInfoResponseToJson(ModelInfoResponse instance) =>
    <String, dynamic>{
      'model_name': instance.modelName,
      'input_shape': instance.inputShape,
      'activity_labels': instance.activityLabels,
      'description': instance.description,
      'version': instance.version,
      'expected_features': instance.expectedFeatures,
    };

PredictionRequest _$PredictionRequestFromJson(Map<String, dynamic> json) =>
    PredictionRequest(
      userId: json['user_id'] as String,
      sensorData: (json['sensor_data'] as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList(),
      inputFormat: json['input_format'] as String? ?? 'raw',
    );

Map<String, dynamic> _$PredictionRequestToJson(PredictionRequest instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'input_format': instance.inputFormat,
      'sensor_data': instance.sensorData,
    };

PredictionResponse _$PredictionResponseFromJson(Map<String, dynamic> json) =>
    PredictionResponse(
      activity: json['activity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      timestamp: (json['timestamp'] as num).toInt(),
      allProbabilities: (json['all_probabilities'] as Map<String, dynamic>?)
          ?.map((k, e) => MapEntry(k, (e as num).toDouble())),
    );

Map<String, dynamic> _$PredictionResponseToJson(PredictionResponse instance) =>
    <String, dynamic>{
      'activity': instance.activity,
      'confidence': instance.confidence,
      'timestamp': instance.timestamp,
      'all_probabilities': instance.allProbabilities,
    };

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      error: json['error'] as String?,
      message: json['message'] as String?,
      code: (json['code'] as num?)?.toInt(),
      detail: json['detail'] as String?,
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
      'message': instance.message,
      'code': instance.code,
      'detail': instance.detail,
    };
