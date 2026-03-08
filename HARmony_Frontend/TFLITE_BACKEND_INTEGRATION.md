# HARmony Frontend - TFLite Backend Integration Guide

## Overview

The HARmony frontend has been completely refactored to integrate with a remote TFLite backend at `http://<backend-host>:8000`. The new integration uses streamlined endpoints and a modernized prediction pipeline with improved error handling and user feedback.

## Architecture Changes

### 1. New Backend API Contract

All communication now uses the following endpoints:

#### Health Check
```
GET /health
Response: {
  "status": "healthy",
  "model_loaded": true,
  "model_name": "har_model_fixed.tflite",
  "message": "Backend is operational"
}
```

#### Model Information
```
GET /model-info
Response: {
  "model_name": "har_model_fixed.tflite",
  "input_shape": [1, 40, 3],
  "activity_labels": ["Walking", "Running", "Sitting", "Standing", "Cycling"],
  "description": "TFLite HAR model",
  "version": "1.0",
  "expected_features": 120
}
```

#### Prediction
```
POST /predict
Request: {
  "user_id": "anonymous",
  "input_format": "raw",
  "sensor_data": [120 float values]
}

Response: {
  "activity": "Walking",
  "confidence": 0.95,
  "timestamp": 1709761200000,
  "all_probabilities": {
    "Walking": 0.95,
    "Running": 0.03,
    "Sitting": 0.02,
    ...
  }
}
```

### 2. Sensor Data Format

**Critical:** The backend expects exactly **120 float values** representing 40 sensor samples × 3 axes (x, y, z).

**Format:** `[x1, y1, z1, x2, y2, z2, ..., x40, y40, z40]`

- 40 timesteps collected at ~50 Hz (0.8 seconds of data)
- Each timestep contributes 3 values: x, y, z acceleration
- Total: 40 × 3 = 120 floats

### 3. New File Structure

#### Created Files:

1. **`models/backend_models.dart`**
   - `HealthCheckResponse` - Backend health status
   - `ModelInfoResponse` - Model metadata and activity labels
   - `PredictionRequest` - Structured request payload (user_id, input_format, sensor_data)
   - `PredictionResponse` - Structured response (activity, confidence, all_probabilities)
   - `ErrorResponse` - Error handling with status codes

2. **`services/backend_status_service.dart`**
   - Manages health checks and model info fetching
   - Implements caching (10-second TTL)
   - Handles connection errors gracefully

3. **`utils/sensor_data_utils.dart`**
   - `flattenSensorWindow()` - Converts SensorWindow to 120-float array
   - `isValidFlatSize()` - Validates sensor data length
   - `getValidationErrorMessage()` - User-friendly error messages

4. **`widgets/backend_status_indicator.dart`**
   - Real-time status indicator (green/red) in app header
   - Shows model_loaded status
   - Tooltip with detailed status

5. **`widgets/sensor_buffering_progress_widget.dart`**
   - Displays current window progress ("27/40 samples collected")
   - Visual progress bar
   - Updates in real-time as samples arrive

6. **`widgets/prediction_result_widget.dart`**
   - Shows confidence score with color coding
   - Displays top 5 probabilities from all_probabilities
   - Probability bar chart with percentages

#### Modified Files:

1. **`services/sensor_service.dart`**
   - Changed window size from 128 to 40 samples
   - Added `bufferingProgressStream` for progress tracking
   - Updated buffer management to handle fixed window size

2. **`services/api_service.dart`**
   - Complete rewrite for new endpoints
   - Removed legacy `/api/*` routes
   - New `predictActivity()` with 120-value validation
   - New `getHealth()` for backend status
   - New `getModelInfo()` for activity labels

3. **`core/app_providers.dart`**
   - Added `backendStatusServiceProvider`
   - Added `healthCheckProvider` with FutureProvider
   - Added `modelInfoProvider` with FutureProvider
   - Added `activityLabelsProvider` to fetch labels dynamically
   - Updated `activityPredictionProvider` to use remote backend

4. **`screens/realtime_screen.dart`**
   - Added backend health status monitoring
   - Integrated new UI widgets (status indicator, progress, results)
   - Enhanced error handling with user-friendly messages
   - Disabled "Start" button when backend is unhealthy
   - Added retry mechanism for failed connections
   - Improved status message display (now red when errors occur)

## Error Handling

### HTTP Status Codes

| Status | Meaning | User Message | Action |
|--------|---------|--------------|--------|
| 200 | Success | Activity displayed | Continue monitoring |
| 400 | Invalid data | "Need exactly 120 sensor values (40x3)." | Validate locally, block request |
| 503 | Model not loaded | "Model not loaded on server. Please check model deployment/runtime." | Show error banner, disable predict, offer retry |
| Other | Network/server error | "Prediction failed: [error]" | Show error, log details |

### Client-Side Validation

Before sending to `/predict`:
```dart
// SensorDataUtils.isValidFlatSize(flatData)
if (flatData.length != 120) {
  // Block request, show error
  // Message: "Need exactly 120 sensor values (40x3)."
}
```

### Backend Status Checks

On app startup:
1. GET `/health` → Check `model_loaded` flag
2. GET `/model-info` → Fetch activity labels
3. If either fails or `model_loaded: false`:
   - Disable "Start Monitoring" button
   - Show red banner: "Model not loaded on server..."
   - Offer "Retry" option

## UX Improvements

### 1. Backend Status Indicator (AppBar)
- **Green dot:** Model loaded and ready
- **Red dot:** Model not loaded or backend unavailable
- **Amber dot + spinner:** Status checking
- **Tooltip:** Detailed status message

### 2. Input Window Progress
- Shows "Collecting samples: X/40"
- Progress bar fills from 0% to 100%
- Color changes to green when ready (40/40)
- Continuous real-time updates

### 3. Status Messages
Now contextual and color-coded:
- **Blue background:** Informational (normal operation)
- **Red background:** Error (backend unavailable, model not loaded)
- Shows both message and backend health status
- Icons indicate current state

### 4. Control Button States
- **Start button enabled:** Backend healthy + model loaded + not monitoring
- **Start button disabled:** Backend unavailable OR model not loaded
- **Disabled state visual:** Gray background
- **Retry option:** Available in error banner

### 5. Prediction Results
Display enhanced with:
- Confidence score (0-100%)
- Color-coded confidence (green > 80%, amber > 60%, red < 60%)
- Top 5 activity probabilities with bar chart
- Percentage for each probability

## Configuration

### Backend URL

Default URLs in `app_providers.dart`:
```dart
- Web/Desktop: http://localhost:8000
- Android Emulator: http://10.0.2.2:8000
- Physical Device: http://192.168.1.5:8000 (modify as needed)
```

Change the `baseUrl` in `apiServiceProvider` to your backend address.

### User ID

Currently set to `"anonymous"` in `api_service.dart`:
```dart
Future<ActivityModel> predictActivity(SensorWindow sensorData,
    {String userId = 'anonymous'}) async {
```

Can be modified to:
- Read from SharedPreferences
- Prompt user at startup
- Load from device settings

## Testing Checklist (QA Scenarios)

### Happy Path
- [ ] Backend is running and healthy
- [ ] Green indicator shows in AppBar
- [ ] Start button is enabled
- [ ] Click "Start Monitoring"
- [ ] Sensor data collected shows 0-40 progress
- [ ] Window fills to 40/40
- [ ] Prediction received with activity + confidence
- [ ] Top probabilities displayed
- [ ] No errors in logcat

### Invalid Sensor Data Length
- [ ] Manually create window with 90 samples
- [ ] Client-side validation blocks request
- [ ] Error message shown: "Need exactly 120 sensor values (40x3)."
- [ ] No network call made

### Backend Unavailable
- [ ] Stop backend server
- [ ] App shows red indicator in AppBar
- [ ] "Model not loaded..." error displayed
- [ ] Start button disabled
- [ ] Click "Retry" → rechecks health
- [ ] When backend restarts, retry connects successfully

### Backend Unhealthy (model_loaded: false)
- [ ] Backend running but model not loaded
- [ ] `/health` returns `"model_loaded": false`
- [ ] Red indicator in AppBar
- [ ] Error message: "Model not loaded on server..."
- [ ] Start button disabled

### 503 Error (Model Loading)
- [ ] Backend temporarily unable to serve model
- [ ] Prediction request returns 503
- [ ] Error banner shown with retry option
- [ ] User can click "Retry"
- [ ] Monitoring stops gracefully

### 400 Error (Invalid Data)
- [ ] Corrupt sensor data sent (e.g., 90 values)
- [ ] Backend returns 400: "Invalid input shape"
- [ ] Client-side validation should prevent this
- [ ] If bypassed, user sees: "Need exactly 120 sensor values (40x3)."

### Network Timeout
- [ ] Slow/unstable network
- [ ] Request times out after 8 seconds
- [ ] Error shown: "Prediction failed: Connection timeout"
- [ ] Monitoring continues, retries on next window

## Implementation Notes

### Sensor Windowing Pipeline

1. **Collection (50 Hz):** Device accelerometer/gyroscope sensors collected continuously
2. **Buffering:** Samples stored in QueueList, max 120 samples (for overflow tolerance)
3. **Window Ready:** When 40+ samples accumulated, emit window to prediction stream
4. **Flatten:** Convert 40 × [x,y,z] to single 120-float array
5. **Validate:** Check length == 120 before sending
6. **Send:** POST to `/predict` with 120 values + user_id + input_format
7. **Response:** Parse activity, confidence, all_probabilities
8. **Display:** Show result with top-N probabilities

### Caching Strategy

- **Health check:** Cached for 10 seconds (prevents excessive checks)
- **Model info:** Cached for 10 seconds (activity labels stable)
- **Predictions:** Not cached (real-time, unique per window)

### Error Recovery

1. **On startup:** Check health → if unhealthy, show error banner
2. **During monitoring:** If prediction fails:
   - Log error
   - Show error snackbar
   - Continue monitoring (don't stop)
   - Retry on next window
3. **User-initiated:** "Retry" button calls `_checkBackendStatus()` again
4. **Graceful degradation:** App remains usable even if backend unavailable

## Migration Checklist

If upgrading from old backend:

- [ ] Update backend to use `/health`, `/model-info`, `/predict` endpoints
- [ ] Backend returns 120-sample TFLite inputs (40 × 3)
- [ ] Backend model loaded with `har_model_fixed.tflite` + `labels.json`
- [ ] Backend health check includes `model_loaded` boolean
- [ ] Backend model-info includes `activity_labels` array
- [ ] Prediction response includes `all_probabilities` map
- [ ] Remove old `/api/*` Flask routes (no longer called by frontend)
- [ ] Update frontend base URL to new backend
- [ ] Run `flutter pub get && flutter run` to rebuild
- [ ] Test all QA scenarios above

## Code Examples

### Manually Testing API Endpoints

```bash
# Health check
curl http://localhost:8000/health

# Model info
curl http://localhost:8000/model-info

# Prediction (example 120 values)
curl -X POST http://localhost:8000/predict \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "test_user",
    "input_format": "raw",
    "sensor_data": [0.1, 0.2, 0.3, ...] # 120 floats
  }'
```

### Accessing Labels Dynamically in UI

```dart
// In any widget that needs labels:
final labelsAsync = ref.watch(activityLabelsProvider);
labelsAsync.whenData((labels) {
  // Use labels: labels = ["Walking", "Running", ...]
});
```

### Checking Backend Status Manually

```dart
// In state or provider:
final statusService = ref.watch(backendStatusServiceProvider);
final health = await statusService.checkHealth();
if (health.modelLoaded) {
  // Safe to predict
}
```

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Backend unreachable | Wrong URL or server down | Check baseUrl in app_providers.dart, verify server running |
| Red indicator always | `/health` endpoint missing | Implement `/health` endpoint on backend |
| 503 errors | Model not loaded on startup | Pre-load model on backend startup, check logs |
| 400 validation errors | Sensor data < 120 values | Ensure 40 samples collected before predicting |
| Labels not showing | `/model-info` missing | Implement `/model-info` with activity_labels array |
| Progress widget stuck at 20/40 | Sensor permission denied | Grant accelerometer/gyroscope permissions |

## Performance Considerations

- **Prediction latency:** ~100-200ms (TFLite inference on device)
- **Network latency:** ~50-200ms depending on WiFi/connection
- **Total E2E latency:** ~200-400ms from window-ready to result display
- **Memory footprint:** Minimal (40-sample buffer ≈ 1KB, no model loaded locally)
- **Power consumption:** Dominated by sensor collection, network negligible

## Future Enhancements

- [ ] Implement confidence smoothing (running average of predictions)
- [ ] Add prediction aggregation (e.g., "walking for 95% of last 2 seconds")
- [ ] Support batch predictions (multiple windows in one request)
- [ ] Implement server-side model switching (A/B testing)
- [ ] Add telemetry/analytics server
- [ ] Cache prediction results with timestamp validation

