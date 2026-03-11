import 'package:flutter/foundation.dart';
import 'package:harmony_app/features/activity_recognition/models/backend_models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

/// Backend connection status enum
enum BackendConnectionStatus {
  connected,        // Backend is reachable
  disconnected,     // Backend is unreachable
  connecting,       // Attempting to connect
  degraded          // Connected but model not loaded
}

/// Service to manage backend health checks and model info.
/// Provides cached info with periodic refresh and auto-reconnection.
class BackendStatusService {
  final String baseUrl;
  static const Duration _timeout = Duration(seconds: 5);
  static const Duration _healthCheckInterval = Duration(seconds: 10);
  static const Duration _cacheDuration = Duration(seconds: 30);

  HealthCheckResponse? _cachedHealth;
  ModelInfoResponse? _cachedModelInfo;
  DateTime? _lastHealthCheck;
  DateTime? _lastModelInfoCheck;
  
  // Connection monitoring
  Timer? _healthCheckTimer;
  final StreamController<BackendConnectionStatus> _connectionStatusStream =
      StreamController<BackendConnectionStatus>.broadcast();
  BackendConnectionStatus _currentStatus = BackendConnectionStatus.disconnected;
  int _consecutiveFailures = 0;
  static const int _maxConsecutiveFailures = 3;

  BackendStatusService({required this.baseUrl}) {
    if (kDebugMode) {
      print('BackendStatusService initialized with baseUrl: $baseUrl');
    }
  }

  /// Get stream of connection status changes
  Stream<BackendConnectionStatus> get connectionStatusStream =>
      _connectionStatusStream.stream;

  /// Get current connection status
  BackendConnectionStatus get currentStatus => _currentStatus;

  /// Start periodic health checks (for app startup)
  void startPeriodicHealthChecks() {
    if (kDebugMode) print('🟢 Starting periodic health checks...');
    
    // Start health check immediately
    _performHealthCheck();
    
    // Then schedule periodic checks
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) {
      _performHealthCheck();
    });
  }

  /// Stop periodic health checks
  void stopPeriodicHealthChecks() {
    if (kDebugMode) print('🔴 Stopping periodic health checks');
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Perform a single health check without caching
  Future<void> _performHealthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      
      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedHealth = HealthCheckResponse.fromJson(data);
        _lastHealthCheck = DateTime.now();
        
        // Update status based on model and database health
        final modelLoaded = _cachedHealth?.modelLoaded ?? false;
        final newStatus = modelLoaded 
            ? BackendConnectionStatus.connected 
            : BackendConnectionStatus.degraded;
        
        _updateConnectionStatus(newStatus);
        _consecutiveFailures = 0;
        
        if (kDebugMode) {
          print('✅ Health check OK: ${_cachedHealth?.status} | Model: ${modelLoaded ? 'loaded' : 'not-loaded'}');
        }
      } else {
        throw Exception('Health check returned status ${response.statusCode}');
      }
    } catch (e) {
      _consecutiveFailures++;
      if (kDebugMode) {
        print('❌ Health check failed ($e) - Failures: $_consecutiveFailures');
      }
      _updateConnectionStatus(BackendConnectionStatus.disconnected);
    }
  }

  /// Check backend health with caching support
  Future<HealthCheckResponse> checkHealth({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached result if available and fresh
    if (!forceRefresh &&
        _cachedHealth != null &&
        _lastHealthCheck != null &&
        now.difference(_lastHealthCheck!) < _cacheDuration) {
      return _cachedHealth!;
    }

    try {
      final uri = Uri.parse('$baseUrl/health');
      if (kDebugMode) print('🔵 GET $uri (health check)');

      final response = await http.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _cachedHealth = HealthCheckResponse.fromJson(data);
        _lastHealthCheck = now;
        
        final modelLoaded = _cachedHealth?.modelLoaded ?? false;
        final newStatus = modelLoaded 
            ? BackendConnectionStatus.connected 
            : BackendConnectionStatus.degraded;
        _updateConnectionStatus(newStatus);
        
        return _cachedHealth!;
      } else {
        throw Exception('Health check returned status ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('❌ checkHealth error: $e');
      _updateConnectionStatus(BackendConnectionStatus.disconnected);
      return HealthCheckResponse(
        status: 'error',
        modelLoaded: false,
        message: 'Health check failed: $e',
      );
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(BackendConnectionStatus newStatus) {
    if (_currentStatus != newStatus) {
      _currentStatus = newStatus;
      if (!_connectionStatusStream.isClosed) {
        _connectionStatusStream.add(newStatus);
      }
      
      if (kDebugMode) {
        print('📡 Connection status: ${newStatus.toString().split('.').last}');
      }
    }
  }

  /// Fetch model info including available activity labels
  Future<ModelInfoResponse?> getModelInfo({bool forceRefresh = false}) async {
    final now = DateTime.now();
    
    // Return cached result if available and fresh
    if (!forceRefresh &&
        _cachedModelInfo != null &&
        _lastModelInfoCheck != null &&
        now.difference(_lastModelInfoCheck!) < _cacheDuration) {
      return _cachedModelInfo;
    }

    try {
      final uri = Uri.parse('$baseUrl/model-info');
      if (kDebugMode) print('🔵 GET $uri (model info)');

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
      if (kDebugMode) print('❌ getModelInfo error: $e');
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

  /// Check if backend is accessible (quick synchronous check)
  bool get isConnected => _currentStatus == BackendConnectionStatus.connected;

  /// Check if backend is in any connected state (including degraded)
  bool get isAccessible => 
      _currentStatus == BackendConnectionStatus.connected ||
      _currentStatus == BackendConnectionStatus.degraded;

  /// Dispose of resources
  void dispose() {
    stopPeriodicHealthChecks();
    _connectionStatusStream.close();
  }
}


