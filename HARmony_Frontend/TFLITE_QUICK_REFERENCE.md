# TFLite Backend Integration - Quick Reference

## Files Modified/Created

### New Files (6)
```
lib/features/activity_recognition/
├── models/
│   └── backend_models.dart ✨
├── services/
│   └── backend_status_service.dart ✨
├── utils/
│   └── sensor_data_utils.dart ✨
└── widgets/
    ├── backend_status_indicator.dart ✨
    ├── sensor_buffering_progress_widget.dart ✨
    └── prediction_result_widget.dart ✨
```

### Modified Files (4)
```
lib/
├── core/app_providers.dart 📝
└── features/activity_recognition/
    ├── services/
    │   ├── api_service.dart 📝
    │   └── sensor_service.dart 📝
    └── screens/
        └── realtime_screen.dart 📝
```

## API Endpoints

### GET /health
```dart
// Check backend status
final health = await apiService.getHealth();
if (health.modelLoaded && health.isHealthy) {
  // Safe to predict
}
```
**Response:** `{"status": "healthy", "model_loaded": true}`

### GET /model-info
```dart
// Fetch activity labels dynamically
final modelInfo = await apiService.getModelInfo();
final labels = modelInfo?.activityLabels ?? [];
```
**Response:** `{"activity_labels": ["Walking", "Running", ...]}`

### POST /predict
```dart
// Send 40 samples (120 floats)
final prediction = await apiService.predictActivity(sensorWindow);
// Returns: ActivityModel(activity, confidence, timestamp)
```
**Request:** `{"user_id": "anon", "input_format": "raw", "sensor_data": [120 floats]}`

## Key Constants

| Constant | Value | Location |
|----------|-------|----------|
| Window size | 40 samples | `sensor_service.dart` |
| Flat array size | 120 floats | `sensor_data_utils.dart` |
| Sampling rate | 50 Hz (20ms) | `sensor_service.dart` |
| HTTP timeout | 8 seconds | `api_service.dart` |
| Health cache | 10 seconds | `backend_status_service.dart` |

## Sensor Data Format

**Input to backend:**
```
[x1, y1, z1, x2, y2, z2, ..., x40, y40, z40]
 ↑   ↑   ↑   ↑   ↑   ↑       ↑   ↑   ↑
 sample 1    sample 2       sample 40
```

**Validation:**
```dart
import 'package:harmony_app/features/activity_recognition/utils/sensor_data_utils.dart';

final flatData = SensorDataUtils.flattenSensorWindow(window);
if (!SensorDataUtils.isValidFlatSize(flatData)) {
  // Error: need exactly 120 values
}
```

## Error Handling

### Status Codes
- **200:** Success ✓
- **400:** Invalid input (not 120 values)
- **503:** Model not loaded (backend issue)
- **Other:** Network/server error

### Handling in UI
```dart
try {
  final prediction = await apiService.predictActivity(window);
  // Display prediction
} on Exception catch (e) {
  if (e.toString().contains('Model not loaded')) {
    // Show: "Model not loaded on server..."
  } else if (e.toString().contains('Need exactly 120')) {
    // Show: "Need exactly 120 sensor values (40x3)."
  } else {
    // Show generic error with retry option
  }
}
```

## Provider Access

```dart
// In ConsumerWidget/ConsumerState:
final ref = ref; // provided by Riverpod

// Backend status
final health = ref.watch(healthCheckProvider);

// Model labels
final labels = ref.watch(activityLabelsProvider);

// Sensor buffering progress
final sensorService = ref.watch(sensorServiceProvider);
final progressStream = sensorService.bufferingProgressStream;

// Predictions
ref.listen<AsyncValue<ActivityModel>>(
  activityPredictionProvider,
  (prev, next) { /* handle */ }
);
```

## UI Widgets

### Backend Status Indicator
```dart
// In AppBar or header:
const BackendStatusIndicator()
// Green dot = ready, Red dot = unhealthy, Amber spinner = checking
```

### Sensor Progress
```dart
// Shows "27/40 samples" with progress bar:
const SensorBufferingProgressWidget()
```

### Prediction Result
```dart
// Display activity, confidence, top probabilities:
PredictionResultWidget(
  activity: 'Walking',
  confidence: 0.92,
  allProbabilities: {'Walking': 0.92, 'Running': 0.05, ...}
)
```

## Configuration

### Change Backend URL
File: `lib/core/app_providers.dart`
```dart
final apiServiceProvider = Provider<ApiService>((ref) {
  String baseUrl = 'http://192.168.1.5:8000'; // ← Modify here
  return ApiService(baseUrl: baseUrl);
});
```

### Change User ID
File: `lib/features/activity_recognition/services/api_service.dart`
```dart
Future<ActivityModel> predictActivity(SensorWindow sensorData,
    {String userId = 'your_user_id'}) async { // ← Modify here
```

## Testing

### Health Check
```bash
curl http://localhost:8000/health
# Expected: {"status": "healthy", "model_loaded": true}
```

### Model Info
```bash
curl http://localhost:8000/model-info
# Expected: {"activity_labels": ["Walking", "Running", ...]}
```

### Prediction
```bash
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{"user_id": "test", "input_format": "raw", "sensor_data": [0.1, 0.2, ...]}'
# Expected: {"activity": "Walking", "confidence": 0.95, "timestamp": 1709761200000}
```

## Common Tasks

### Refresh Backend Status
```dart
// Manual refresh (clears cache):
final statusService = ref.watch(backendStatusServiceProvider);
statusService.clearCache();
await statusService.checkHealth();
```

### Access Activity Labels
```dart
final labelAsync = ref.watch(activityLabelsProvider);
labelAsync.whenData((labels) {
  // Use labels for dropdowns, filters, etc.
  labels.forEach((label) { /* ... */ });
});
```

### Log Sensor Window
```dart
import 'package:harmony_app/features/activity_recognition/utils/sensor_data_utils.dart';

final flatData = SensorDataUtils.flattenSensorWindow(window);
print('Sensor data (${flatData.length} values): $flatData');
```

### Custom Error Message
```dart
final errorMsg = ErrorResponse(code: 400).displayMessage;
// Returns: "Need exactly 120 sensor values (40x3)."
```

## Performance Notes

| Metric | Value | Notes |
|--------|-------|-------|
| TFLite inference | ~100-200ms | On-server time |
| Network latency | ~50-200ms | WiFi dependent |
| Total E2E | ~200-400ms | From window-ready to display |
| Memory overhead | ~1KB | 40-sample buffer |
| CPU (idle) | Minimal | Polling-based checks |

## Deprecated (Do Not Use)

❌ `/api/predict` - Use `/predict` instead
❌ `/api/activities` - Not supported in new backend
❌ `/api/health` - Use `/health` instead
❌ `ModelInferenceService` - Now using remote backend
❌ Old sklearn model - Replaced with TFLite

## Debugging

### Enable Debug Logs
```dart
// In api_service.dart or backend_status_service.dart:
if (kDebugMode) print('Debug message: $value');
```

### Check Sensor Buffer
```dart
final sensorService = ref.read(sensorServiceProvider);
print('Buffer size: ${sensorService.currentBufferSize}');
print('Buffer data: ${sensorService.accelerometerEvents}');
```

### Monitor Prediction Stream
```dart
ref.listen<AsyncValue<ActivityModel>>(
  activityPredictionProvider,
  (prev, next) {
    next.whenData((pred) => print('Prediction: ${pred.activity} (${pred.confidence})'));
    next.whenError((err, _) => print('Error: $err'));
  }
);
```

## Resources

- 📖 Full Integration Guide: `TFLITE_BACKEND_INTEGRATION.md`
- 📝 Backend Models: `models/backend_models.dart`
- 🔧 API Service: `services/api_service.dart`
- 📊 Real-time Screen: `screens/realtime_screen.dart`

