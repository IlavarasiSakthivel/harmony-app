import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/features/activity_recognition/models/backend_models.dart';
import 'package:harmony_app/features/activity_recognition/services/activity_storage_service.dart';
import 'package:harmony_app/features/activity_recognition/services/api_service.dart';
import 'package:harmony_app/features/activity_recognition/services/backend_status_service.dart';
import 'package:harmony_app/features/activity_recognition/services/sensor_service.dart';
import 'package:harmony_app/core/config/app_config.dart';
import 'package:harmony_app/core/services/backend_config_service.dart';
import 'package:harmony_app/shared/database/app_database.dart';
import 'package:harmony_app/shared/services/model_inference_service.dart';

import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

final sensorServiceProvider = Provider<SensorService>((ref) {
  final s = SensorService();
  ref.onDispose(() => s.dispose());
  return s;
});

/// Configuration provider that exposes a mutable backend URL stored in
/// shared preferences.  The value is initialized to AppConfig.apiBaseUrl and
/// can be overridden by users if their host IP changes.
final backendConfigProvider = ChangeNotifierProvider<BackendConfigService>((ref) {
  final cfg = BackendConfigService();
  return cfg;
});

/// Provide the ApiService configured to point at Flask backend with PostgreSQL
/// Use 10.0.2.2 for Android emulators to access localhost on the host machine
final apiServiceProvider = Provider<ApiService>((ref) {
  final cfg = ref.watch(backendConfigProvider);
  final String baseUrl = cfg.baseUrl;

  if (kDebugMode) {
    print('🔗 API Service configured to: $baseUrl');
  }

  return ApiService(baseUrl: baseUrl);
});

/// Backend status service for health checks and model info
final backendStatusServiceProvider = Provider<BackendStatusService>((ref) {
  final cfg = ref.watch(backendConfigProvider);
  final String baseUrl = cfg.baseUrl;

  if (kDebugMode) {
    print('🔗 Backend Status Service configured to: $baseUrl');
  }

  return BackendStatusService(baseUrl: baseUrl);
});

/// Health check provider - fetches model status from /health endpoint
final healthCheckProvider = FutureProvider<HealthCheckResponse>((ref) async {
  final statusService = ref.watch(backendStatusServiceProvider);
  return statusService.checkHealth();
});

/// Backend connection status stream provider - broadcasts connection state changes
final backendConnectionStatusProvider =
    StreamProvider<BackendConnectionStatus>((ref) async* {
  final statusService = ref.watch(backendStatusServiceProvider);
  
  // Start periodic health checks when this provider is first watched
  statusService.startPeriodicHealthChecks();
  ref.onDispose(() {
    statusService.stopPeriodicHealthChecks();
  });
  
  // Emit current status
  yield statusService.currentStatus;
  
  // Then emit all status changes
  await for (final status in statusService.connectionStatusStream) {
    yield status;
  }
});

/// Model info provider - fetches available labels from /model-info endpoint
final modelInfoProvider = FutureProvider<ModelInfoResponse>((ref) async {
  final statusService = ref.watch(backendStatusServiceProvider);
  final modelInfo = await statusService.getModelInfo();

  if (modelInfo != null) {
    return modelInfo;
  }

  // Fallback to default labels if model info unavailable
  return ModelInfoResponse(
    modelName: 'har_model_fixed.tflite',
    inputShape: [1, 120],
    activityLabels: [
      'Walking',
      'Running',
      'Sitting',
      'Standing',
      'Jogging',
      'Cycling',
      'Climbing',
      'Descending'
    ],
    description: 'Fallback model info - server unavailable',
    version: '1.0',
    expectedFeatures: 120,
  );
});

/// Activity labels provider - extracts labels from model info
final activityLabelsProvider = FutureProvider<List<String>>((ref) async {
  final modelInfo = await ref.watch(modelInfoProvider.future);
  return modelInfo.activityLabels;
});

final activityStorageServiceProvider = Provider<ActivityStorageService>((ref) {
  final db = ref.watch(appDatabaseProvider).value;
  return ActivityStorageService(database: db);
});

final modelInferenceServiceProvider = Provider<ModelInferenceService>((ref) {
  final s = ModelInferenceService();
  ref.onDispose(() => s.dispose());
  return s;
});

/// Remote Flask backend predictions with PostgreSQL storage
/// Sensors must be started and will emit windows continuously
final activityPredictionProvider = StreamProvider<ActivityModel>((ref) async* {
  final sensorService = ref.watch(sensorServiceProvider);
  final apiService = ref.watch(apiServiceProvider);

  await for (final window in sensorService.inferenceReadyStream) {
    try {
      final prediction = await apiService.predictActivity(window);
      yield prediction;
    } catch (e) {
      // Log error but continue receiving windows
      if (kDebugMode) {
        print('❌ Prediction error: $e');
      }
    }
  }
});

final currentActivityProvider = StateProvider<ActivityModel>((ref) {
  return ActivityModel(
    activity: 'Unknown',
    confidence: 0.0,
    timestamp: DateTime.now().millisecondsSinceEpoch,
  );
});

/// Local Floor database for offline sync and history
final appDatabaseProvider = FutureProvider<AppDatabase>((ref) async {
  return AppDatabase.open();
});
