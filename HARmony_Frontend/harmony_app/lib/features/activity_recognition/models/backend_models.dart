import 'package:json_annotation/json_annotation.dart';

part 'backend_models.g.dart';

/// Response from GET /health
@JsonSerializable()
class HealthCheckResponse {
  final String status;
  @JsonKey(name: 'model_loaded')
  final bool modelLoaded;
  @JsonKey(name: 'model_name')
  final String? modelName;
  final String? message;

  HealthCheckResponse({
    required this.status,
    required this.modelLoaded,
    this.modelName,
    this.message,
  });

  factory HealthCheckResponse.fromJson(Map<String, dynamic> json) =>
      _$HealthCheckResponseFromJson(json);
  Map<String, dynamic> toJson() => _$HealthCheckResponseToJson(this);

  bool get isHealthy => status == 'healthy' || status == 'ok';
}

/// Response from GET /model-info
@JsonSerializable()
class ModelInfoResponse {
  @JsonKey(name: 'model_name')
  final String modelName;
  @JsonKey(name: 'input_shape')
  final List<int> inputShape;
  @JsonKey(name: 'activity_labels')
  final List<String> activityLabels;
  final String? description;
  final String? version;
  @JsonKey(name: 'expected_features')
  final int? expectedFeatures; // Should be 120 (40 samples * 3 axes)

  ModelInfoResponse({
    required this.modelName,
    required this.inputShape,
    required this.activityLabels,
    this.description,
    this.version,
    this.expectedFeatures,
  });

  factory ModelInfoResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ModelInfoResponseToJson(this);
}

/// Request payload for POST /predict
@JsonSerializable()
class PredictionRequest {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'input_format')
  final String inputFormat; // Always "raw"
  @JsonKey(name: 'sensor_data')
  final List<double> sensorData; // Exactly 120 float values

  PredictionRequest({
    required this.userId,
    required this.sensorData,
    this.inputFormat = 'raw',
  });

  factory PredictionRequest.fromJson(Map<String, dynamic> json) =>
      _$PredictionRequestFromJson(json);
  Map<String, dynamic> toJson() => _$PredictionRequestToJson(this);
}

/// Response from POST /predict
@JsonSerializable()
class PredictionResponse {
  final String activity;
  final double confidence;
  final int timestamp; // Unix timestamp in milliseconds
  @JsonKey(name: 'all_probabilities')
  final Map<String, double>? allProbabilities; // Optional: { "walking": 0.85, "running": 0.1, ... }

  PredictionResponse({
    required this.activity,
    required this.confidence,
    required this.timestamp,
    this.allProbabilities,
  });

  factory PredictionResponse.fromJson(Map<String, dynamic> json) =>
      _$PredictionResponseFromJson(json);
  Map<String, dynamic> toJson() => _$PredictionResponseToJson(this);
}

/// Represents error response from backend
@JsonSerializable()
class ErrorResponse {
  final String? error;
  final String? message;
  final int? code;
  final String? detail;

  ErrorResponse({
    this.error,
    this.message,
    this.code,
    this.detail,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  String get displayMessage {
    if (code == 400) {
      return 'Need exactly 120 sensor values (40x3).';
    } else if (code == 503) {
      return 'Model not loaded on server. Please check model deployment/runtime.';
    }
    return message ?? error ?? 'Unknown error from server';
  }
}

