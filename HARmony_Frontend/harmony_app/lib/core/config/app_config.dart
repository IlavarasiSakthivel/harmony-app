/// App Configuration - Backend URLs, timeouts, and settings
import 'dart:io' show Platform;

class AppConfig {
  // Backend Configuration
  static String get backendBaseUrl {
    // Always point at localhost:8000.  During development we use adb reverse
    // to forward the device's localhost port back to the host machine.  Run
    // `adb reverse tcp:8000 tcp:8000` once before launching the app and the
    // mobile client can simply use http://localhost:8000 regardless of the
    // network configuration.  This avoids Wi‑Fi/VPN/firewall headaches.
    return 'http://localhost:8000';
  }
  // NOTE: backend endpoints are mounted at root; do not append '/api' here
  static String get apiBaseUrl => backendBaseUrl;
  
  // API Endpoints
  static const String healthCheckEndpoint = '/health';
  static const String predictEndpoint = '/predict';
  static const String activitiesEndpoint = '/activities';
  static const String modelInfoEndpoint = '/model-info';
  static const String coachInsightsEndpoint = '/coach-insights';
  
  // Timeouts (milliseconds)
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 10);
  
  // Feature Flags
  static const bool enableOfflineMode = true;
  static const bool enableCaching = true;
  static const bool enableLogging = true;
  
  // Sensor Configuration
  static const int sensorSamplingRate = 50; // Hz
  static const int windowSize = 128;
  static const double confidenceThreshold = 0.7;
  
  // Cache Configuration
  static const Duration cacheDuration = Duration(hours: 1);
  static const int maxCacheSize = 100; // items
}
