/// App Configuration - Backend URLs, timeouts, and settings
class AppConfig {
  // Backend Configuration
  static const String backendBaseUrl = 'http://localhost:8000';
  static const String apiBaseUrl = '$backendBaseUrl/api';
  
  // For Android Device/Emulator - Replace with your actual backend IP
  // static const String backendBaseUrl = 'http://192.168.x.x:8000';
  // static const String apiBaseUrl = '$backendBaseUrl/api';
  
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
