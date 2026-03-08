import 'package:flutter/foundation.dart';
import 'package:harmony_app/features/activity_recognition/models/backend_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Service to manage backend health checks and model info.
/// Provides cached info with periodic refresh.
class BackendStatusService {
  final String baseUrl;
  static const Duration _timeout = Duration(seconds: 5);

  HealthCheckResponse? _cachedHealth;
  ModelInfoResponse? _cachedModelInfo;
  DateTime? _lastHealthCheck;
  DateTime? _lastModelInfoCheck;
  static const Duration _cacheDuration = Duration(seconds: 10);

  BackendStatusService({required this.baseUrl});

  /// Check backend health. Returns cached result if available and fresh.
  Future<HealthCheckResponse> checkHealth() async {
    final now = DateTime.now();
    if (_cachedHealth != null &&
        _lastHealthCheck != null &&
        now.difference(_lastHealthCheck!) < _cacheDuration) {
      return _cachedHealth!;
    }

    try {
      final uri = Uri.parse('$baseUrl/health');
      if (kDebugMode) print('BackendStatusService: GET $uri');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedHealth = HealthCheckResponse.fromJson(data);
        _lastHealthCheck = now;
        return _cachedHealth!;
      } else {
        throw Exception('Health check returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('BackendStatusService.checkHealth error: $e');
      // Return unhealthy status on error
      _cachedHealth = HealthCheckResponse(
        status: 'unhealthy',
        modelLoaded: false,
        message: e.toString(),
      );
      _lastHealthCheck = now;
      return _cachedHealth!;
    }
  }

  /// Fetch model info including available activity labels.
  Future<ModelInfoResponse?> getModelInfo() async {
    final now = DateTime.now();
    if (_cachedModelInfo != null &&
        _lastModelInfoCheck != null &&
        now.difference(_lastModelInfoCheck!) < _cacheDuration) {
      return _cachedModelInfo;
    }

    try {
      final uri = Uri.parse('$baseUrl/model-info');
      if (kDebugMode) print('BackendStatusService: GET $uri');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedModelInfo = ModelInfoResponse.fromJson(data);
        _lastModelInfoCheck = now;
        return _cachedModelInfo;
      } else {
        if (kDebugMode) print('getModelInfo returned status ${response.statusCode}');
        return null;
      }
    } catch (e) {
      if (kDebugMode) print('BackendStatusService.getModelInfo error: $e');
      return null;
    }
  }

  /// Clear cache to force refresh on next call
  void clearCache() {
    _cachedHealth = null;
    _cachedModelInfo = null;
    _lastHealthCheck = null;
    _lastModelInfoCheck = null;
  }

  /// Get activity labels from cached model info, or empty list if unavailable
  List<String> getCachedActivityLabels() {
    return _cachedModelInfo?.activityLabels ?? [];
  }
}

