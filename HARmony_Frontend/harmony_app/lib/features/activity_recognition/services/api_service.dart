import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';
import 'package:harmony_app/features/activity_recognition/models/backend_models.dart';
import 'package:harmony_app/core/config/app_config.dart';
import 'package:flutter/foundation.dart';

// Re-export ActivitySession and ActivityPrediction from activity_model
export 'package:harmony_app/features/activity_recognition/models/activity_model.dart'
    show ActivitySession, ActivityPrediction;

/// API service for TFLite backend at port 8000
/// Endpoints: /health, /model-info, /predict
/// Sensor data: flat array of 120 float values (40 samples x 3 axes)
class ApiService {
  final String baseUrl;
  
  // Default HTTP client with improved configuration
  static final http.Client _httpClient = http.Client();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  /// POST /predict with 120-value flattened sensor data
  /// Returns activity prediction with confidence
  Future<ActivityModel> predictActivity(SensorWindow sensorData,
      {String userId = 'anonymous'}) async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.predictEndpoint}');

      // Validate sensor window has exactly 40 samples
      if (sensorData.accelerometer.length != 40) {
        throw Exception(
            'Invalid sensor window: got ${sensorData.accelerometer.length} samples, need exactly 40');
      }

      // Flatten accelerometer data: [x1,y1,z1,x2,y2,z2,...,x40,y40,z40]
      final List<double> flattenedData = [];
      for (final sample in sensorData.accelerometer) {
        if (sample.length != 3) {
          throw Exception(
              'Invalid sample: got ${sample.length} values, need exactly 3 (x,y,z)');
        }
        flattenedData.add(sample[0].toDouble()); // x
        flattenedData.add(sample[1].toDouble()); // y
        flattenedData.add(sample[2].toDouble()); // z
      }

      // Validate exactly 120 values
      if (flattenedData.length != 120) {
        throw Exception(
            'Need exactly 120 sensor values (40x3). Got ${flattenedData.length}');
      }

      final request = PredictionRequest(
        userId: userId,
        sensorData: flattenedData,
        inputFormat: 'raw',
      );

      final body = jsonEncode(request.toJson());

      if (kDebugMode) {
        print('🔵 POST $uri with ${flattenedData.length} sensor values');
      }

      final response = await _httpClient
          .post(uri, headers: {'Content-Type': 'application/json'}, body: body)
          .timeout(AppConfig.sendTimeout + AppConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final predictionResp = PredictionResponse.fromJson(data);

        return ActivityModel(
          activity: predictionResp.activity,
          confidence: predictionResp.confidence.clamp(0.0, 1.0),
          timestamp: predictionResp.timestamp,
        );
      } else if (response.statusCode == 400) {
        throw Exception('Invalid sensor data: Need exactly 120 sensor values (40x3)');
      } else if (response.statusCode == 503) {
        throw Exception('Model not loaded on server. Please check model deployment/runtime.');
      } else {
        throw Exception('Server returned ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ ApiService.predictActivity error: $e');
      rethrow;
    }
  }

  /// GET /health - Check backend health status
  Future<bool> checkConnection() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.healthCheckEndpoint}');
      if (kDebugMode) print('🔵 GET $uri (health check)');

      final resp = await _httpClient.get(uri).timeout(AppConfig.connectionTimeout);
      return resp.statusCode == 200;
    } catch (e) {
      if (kDebugMode) print('❌ checkConnection error: $e');
      return false;
    }
  }

  /// Fetch all available activity labels from server
  Future<List<String>> fetchActivityLabels() async {
    try {
      final uri = Uri.parse('$baseUrl${AppConfig.modelInfoEndpoint}');
      if (kDebugMode) print('🔵 GET $uri (activity labels)');

      final resp = await _httpClient.get(uri).timeout(AppConfig.receiveTimeout);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final modelInfo = ModelInfoResponse.fromJson(data);
        return modelInfo.activityLabels;
      }
      return ['Walking', 'Running', 'Sitting', 'Standing'];
    } catch (e) {
      if (kDebugMode) print('❌ fetchActivityLabels error: $e');
      return ['Walking', 'Running', 'Sitting', 'Standing'];
    }
  }

  /// Legacy: Fetch remote sessions (not supported on new backend)
  Future<List<ActivitySession>> fetchRemoteSessions(
      {String? userId, String? date}) async {
    return [];
  }

  /// Legacy: Save session to remote database (not supported on new backend)
  Future<bool> saveSessionRemote(ActivitySession session) async {
    return false;
  }

  /// Legacy: Fetch coach insights (not supported on new backend)
  Future<Map<String, dynamic>?> fetchCoachInsights() async {
    return null;
  }

  /// Legacy: Fetch analytics summary (not supported on new backend)
  Future<Map<String, dynamic>?> fetchAnalyticsSummary(String range) async {
    return null;
  }

  /// Legacy: Fetch quick test count (not supported on new backend)
  Future<int> getQuickTestCount() async {
    return 0;
  }

  /// Legacy: Fetch health snapshot (not supported on new backend)
  Future<Map<String, dynamic>?> fetchHealthSnapshot(String dateIso) async {
    return null;
  }

  /// Legacy: Fetch model insights (not supported on new backend)
  Future<Map<String, dynamic>?> fetchModelInsights() async {
    return null;
  }

  /// Legacy: Fetch timeline data (not supported on new backend)
  Future<List<Map<String, dynamic>>> fetchTimeline(String dateIso) async {
    return [];
  }
}


