# TFLite Backend Integration - Architecture Diagram

## System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          HARMONY FRONTEND (FLUTTER)                      │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐   │
│  │                    REAL-TIME RECOGNITION SCREEN                  │   │
│  ├──────────────────────────────────────────────────────────────────┤   │
│  │                                                                   │   │
│  │  AppBar: [Status Indicator •] ← BackendStatusIndicator          │   │
│  │          (Green = Ready, Red = Unhealthy)                        │   │
│  │                                                                   │   │
│  │  Body:                                                           │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │ Status Message (Blue/Red)                               │   │   │
│  │  │ Backend: [Status Icon] + "Ready" / "Unavailable"        │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │ INPUT WINDOW: 27/40 samples [████████░░░░░░]           │   │   │
│  │  │ ← SensorBufferingProgressWidget                          │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │ CURRENT ACTIVITY: Walking                                │   │   │
│  │  │ CONFIDENCE: 95% [████████████████████░]                 │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  ┌──────────────────────────────────────────────────────────┐   │   │
│  │  │ TOP PROBABILITIES:                                       │   │   │
│  │  │ Walking      ████████████████░░░ 95%                    │   │   │
│  │  │ Running      ███░░░░░░░░░░░░░░░░  3%                    │   │   │
│  │  │ Sitting      ██░░░░░░░░░░░░░░░░░░  2%                    │   │   │
│  │  │ ← PredictionResultWidget                                │   │   │
│  │  └──────────────────────────────────────────────────────────┘   │   │
│  │                                                                   │   │
│  │  [Start Monitoring] [Stop] [Reset] (conditionally enabled)      │   │
│  │                                                                   │   │
│  └──────────────────────────────────────────────────────────────────┘   │
│                                                                           │
├─────────────────────────────────────────────────────────────────────────┤
│                          PROVIDER LAYER (RIVERPOD)                       │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────┐         │
│  │ healthCheckProvider (FutureProvider<HealthCheckResponse>)   │         │
│  │  • Calls: apiService.getHealth()                            │         │
│  │  • Returns: {status, model_loaded, model_name, message}     │         │
│  │  • Used by: AppBar indicator, control button state          │         │
│  └─────────────────────────────────────────────────────────────┘         │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────┐         │
│  │ modelInfoProvider (FutureProvider<ModelInfoResponse>)       │         │
│  │  • Calls: apiService.getModelInfo()                         │         │
│  │  • Returns: {model_name, input_shape, activity_labels, ...} │         │
│  │  • Used by: Dynamic label loading, UI initialization        │         │
│  └─────────────────────────────────────────────────────────────┘         │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────┐         │
│  │ activityLabelsProvider (FutureProvider<List<String>>)       │         │
│  │  • Gets labels from: modelInfoProvider                      │         │
│  │  • Used by: Dropdowns, filters, prediction displays         │         │
│  └─────────────────────────────────────────────────────────────┘         │
│                                                                           │
│  ┌─────────────────────────────────────────────────────────────┐         │
│  │ activityPredictionProvider (StreamProvider<ActivityModel>)  │         │
│  │  • Source: sensorService.inferenceReadyStream (40 samples)  │         │
│  │  • For each window: apiService.predictActivity(window)      │         │
│  │  • Returns: {activity, confidence, timestamp}               │         │
│  │  • Error handling: Catches 400, 503, timeouts               │         │
│  │  • Used by: Real-time screen listener                       │         │
│  └─────────────────────────────────────────────────────────────┘         │
│                                                                           │
├─────────────────────────────────────────────────────────────────────────┤
│                       SERVICE & UTILITY LAYER                            │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌────────────────────────────────┐  ┌──────────────────────────────┐   │
│  │   SensorService (50Hz)         │  │  SensorDataUtils             │   │
│  ├────────────────────────────────┤  ├──────────────────────────────┤   │
│  │ • startSensors()               │  │ • flattenSensorWindow()      │   │
│  │ • stopSensors()                │  │   40×[x,y,z] → 120 floats    │   │
│  │ • bufferingProgressStream      │  │ • isValidFlatSize()          │   │
│  │   (emits: {collected, needed}) │  │ • getValidationErrorMessage()│   │
│  │ • inferenceReadyStream         │  │                              │   │
│  │   (emits: SensorWindow@40 smpls)  │                              │   │
│  │                                │  │ Exports: constant = 120      │   │
│  └────────────────────────────────┘  └──────────────────────────────┘   │
│                                                                           │
│  ┌────────────────────────────────┐  ┌──────────────────────────────┐   │
│  │   ApiService                   │  │  BackendStatusService        │   │
│  ├────────────────────────────────┤  ├──────────────────────────────┤   │
│  │ • predictActivity(window)      │  │ • checkHealth()              │   │
│  │   - Flatten to 120 floats      │  │   Cached: 10s                │   │
│  │   - Validate length            │  │ • getModelInfo()             │   │
│  │   - POST to /predict           │  │   Cached: 10s                │   │
│  │   - Parse response             │  │ • clearCache()               │   │
│  │   - Error: 400, 503, timeout   │  │ • getCachedActivityLabels()  │   │
│  │                                │  │                              │   │
│  │ • getHealth()                  │  │ Used by: providers           │   │
│  │   GET /health                  │  │                              │   │
│  │                                │  │                              │   │
│  │ • getModelInfo()               │  │                              │   │
│  │   GET /model-info              │  │                              │   │
│  │                                │  │                              │   │
│  │ Timeout: 8 seconds             │  │                              │   │
│  └────────────────────────────────┘  └──────────────────────────────┘   │
│                                                                           │
│  ┌────────────────────────────────┐                                      │
│  │   Backend Model Classes        │                                      │
│  ├────────────────────────────────┤                                      │
│  │ • HealthCheckResponse          │                                      │
│  │ • ModelInfoResponse            │                                      │
│  │ • PredictionRequest            │                                      │
│  │ • PredictionResponse           │                                      │
│  │ • ErrorResponse                │                                      │
│  │                                │                                      │
│  │ All with JSON serialization    │                                      │
│  └────────────────────────────────┘                                      │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 │ HTTP/Network
                                 ↓
┌─────────────────────────────────────────────────────────────────────────┐
│               TFLITE BACKEND (http://<host>:8000)                        │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────┐        │
│  │ GET /health                                                   │        │
│  │ Response: {                                                   │        │
│  │   "status": "healthy",                                        │        │
│  │   "model_loaded": true,                                       │        │
│  │   "model_name": "har_model_fixed.tflite",                    │        │
│  │   "message": "Backend operational"                            │        │
│  │ }                                                             │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────┐        │
│  │ GET /model-info                                               │        │
│  │ Response: {                                                   │        │
│  │   "model_name": "har_model_fixed.tflite",                    │        │
│  │   "input_shape": [1, 40, 3],                                 │        │
│  │   "activity_labels": ["Walking", "Running", "Sitting", ...], │        │
│  │   "expected_features": 120,                                  │        │
│  │   "version": "1.0"                                           │        │
│  │ }                                                             │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────┐        │
│  │ POST /predict                                                 │        │
│  │                                                               │        │
│  │ Request: {                                                    │        │
│  │   "user_id": "anonymous",                                     │        │
│  │   "input_format": "raw",                                      │        │
│  │   "sensor_data": [120 floats]                                │        │
│  │ }                                                             │        │
│  │                                                               │        │
│  │ Response (200): {                                             │        │
│  │   "activity": "Walking",                                      │        │
│  │   "confidence": 0.95,                                         │        │
│  │   "timestamp": 1709761200000,                                │        │
│  │   "all_probabilities": {                                      │        │
│  │     "Walking": 0.95,                                          │        │
│  │     "Running": 0.03,                                          │        │
│  │     "Sitting": 0.02,                                          │        │
│  │     ...                                                       │        │
│  │   }                                                           │        │
│  │ }                                                             │        │
│  │                                                               │        │
│  │ Errors:                                                       │        │
│  │ • 400: Invalid input (not 120 values)                         │        │
│  │ • 503: Model not loaded / backend busy                        │        │
│  │                                                               │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────┐        │
│  │ Internal:                                                     │        │
│  │ • har_model_fixed.tflite (loaded at startup)                 │        │
│  │ • labels.json (activity labels)                              │        │
│  │                                                               │        │
│  └──────────────────────────────────────────────────────────────┘        │
│                                                                           │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagram

```
SENSOR COLLECTION (50 Hz) → BUFFERING → WINDOWING → PREDICTION → RESULT DISPLAY
     ↓                          ↓            ↓            ↓            ↓
Accelerometer                40-sample     Flatten    API Request   UI Update
Gyroscope                    window to     to 120    /predict       Show:
  ↓                          SensorWindow  floats    endpoint        • Activity
  ├─ x, y, z                   ↓            ↓         ↓              • Confidence
  ├─ x, y, z                 Buffer@40   [x1,y1,z1,  Validate       • Top probs
  ├─ x, y, z    →  QueueList   smpls   x2,y2,z2,...  length
  └─ ...                       Emit        x40,y40,  Must be
     (1000 Hz                  window     z40]        120 floats
      raw)                     progress              
                               to UI                 
                                                     POST JSON
                                                     ↓
                                                     Backend
                                                     TFLite
                                                     Model
```

---

## Prediction Pipeline State Machine

```
┌─────────────────┐
│   APP START     │
└────────┬────────┘
         │
         ↓
    ┌─────────────┐         ┌──────────────────┐
    │ CHECK HEALTH│──ERROR──→│ SHOW RED STATUS  │
    └─────┬───────┘         │ DISABLE START BTN│
          │                 └──────────────────┘
          ├─ model_loaded: true → GREEN STATUS
          │
          ↓
    ┌──────────────────┐
    │ FETCH MODEL INFO │
    │ (activity labels)│
    └──────┬───────────┘
           │
           ↓
    ┌────────────────────┐
    │  READY TO PREDICT  │
    │ START BTN ENABLED  │
    └─────────┬──────────┘
              │
              │ (User clicks START)
              ↓
    ┌──────────────────────┐
    │  START SENSORS       │
    │  • Begin collection  │
    │  • Emit progress: 0% │
    └─────────┬────────────┘
              │
              ↓ (After 40 samples)
    ┌──────────────────────┐
    │  WINDOW READY: 40/40 │
    │  • Emit progress: 100%
    │  • Emit SensorWindow │
    └─────────┬────────────┘
              │
              ↓
    ┌──────────────────────┐
    │  VALIDATE & FLATTEN  │
    │  • 40 samples        │
    │  • → 120 floats      │
    │  • Validate length   │
    └─────────┬────────────┘
              │
              ↓
    ┌──────────────────────┐
    │  SEND TO /predict    │
    │  • POST 120 values   │
    │  • user_id           │
    │  • input_format: raw │
    │  • Timeout: 8s       │
    └─────────┬────────────┘
              │
         ┌────┴────┬─────────┬─────────┐
         │          │         │         │
         ↓ 200      ↓ 400     ↓ 503     ↓ timeout
    ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
    │SUCCESS │ │INVALID │ │NO MODEL│ │TIMEOUT │
    │        │ │        │ │        │ │        │
    │activity│ │"Need   │ │"Model  │ │RETRY   │
    │confide │ │120 val"│ │not     │ │next    │
    │probabs │ │        │ │loaded" │ │window  │
    │        │ │BLOCK   │ │STOP    │ │        │
    │DISPLAY │ │REQUEST │ │SHOW    │ │        │
    │UPDATE  │ │SHOW    │ │ERROR   │ │        │
    │HISTORY │ │ERROR   │ │DISABLE │ │        │
    └────┬───┘ └────┬───┘ └────┬───┘ └────┬───┘
         │          │          │          │
         └──────────┼──────────┼──────────┘
                    │
                    ↓
           ┌────────────────────┐
           │  RESET BUFFER      │
           │  Start next 40     │
           │  samples collection│
           └─────────┬──────────┘
                     │
                     └──→ (repeat prediction loop)
                          or
                     (User clicks STOP)
                          ↓
                     ┌─────────────┐
                     │  STOP/RESET │
                     │  • Stop sens│
                     │  • Clear buf│
                     │  • Save sess│
                     │  • Ready→   │
                     └─────────────┘
```

---

## Error Handling Flow

```
┌──────────────────────────┐
│  PREDICTION FAILS        │
└────────┬─────────────────┘
         │
    ┌────┴────────────────────────────────────────┐
    │                                             │
    ↓ HTTP 400                                    ↓ HTTP 503
 Invalid Data                                Model Not Loaded
 • Validation message:                       • System message:
   "Need exactly 120"                          "Model not loaded..."
   "sensor values (40×3)"                     • UI Action:
 • UI Action:                                   - Show red banner
   - Block request (client-side)                - Disable START btn
   - Show error snackbar                        - Offer RETRY
   - Continue monitoring                      • Monitoring:
   - Retry next window                          - STOPS
                                              - Can resume if fixed
    │                                             │
    └────────────────┬─────────────────────────────┘
                     │
                     ↓ Both errors caught at:
                  listener<AsyncValue>
                  in realtime_screen.dart
                     │
         ┌───────────┼────────────┐
         │           │            │
         ↓           ↓            ↓
    Display     Log error    Update UI
    Snackbar                 state
    with msg               
         │
         └─→ Continue monitoring
             or Stop if critical
```

---

## Widget Hierarchy

```
RealtimeRecognitionScreen
├── Scaffold
│   ├── AppBar
│   │   ├── Title: "Real-time Recognition"
│   │   └── BackendStatusIndicator
│   │       └── Shows: Green/Red/Amber dot
│   │
│   └── Body
│       └── Column
│           ├── Status Message Container
│           │   ├── Text: Status message
│           │   └── Icon: Status/error icon
│           │
│           ├── SensorBufferingProgressWidget
│           │   ├── Text: "27/40 samples"
│           │   └── LinearProgressIndicator
│           │
│           ├── Activity Card
│           │   ├── Activity name (large)
│           │   ├── Confidence bar
│           │   └── Confidence %
│           │
│           ├── Stats Grid
│           │   ├── Steps
│           │   ├── Predictions
│           │   ├── Duration
│           │   ├── Data Feed
│           │   └── Status
│           │
│           ├── Prediction History
│           │   └── ListView of recent predictions
│           │
│           ├── Sensor Data Chart
│           │   └── LineChart (X/Y/Z axes)
│           │
│           ├── Control Buttons
│           │   ├── Start Monitoring
│           │   ├── Stop
│           │   ├── Reset Session
│           │   └── Error Banner (if needed)
│           │
│           └── Footer Text
```

---

## Configuration & Deployment

```
┌──────────────────────────────────────────────────────────────┐
│                   DEPLOYMENT CHECKLIST                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│ Backend Team:                                                 │
│ ├─ [ ] Implement GET /health                                │
│ ├─ [ ] Implement GET /model-info                            │
│ ├─ [ ] Implement POST /predict                              │
│ ├─ [ ] Load har_model_fixed.tflite                          │
│ ├─ [ ] Load labels.json                                     │
│ └─ [ ] Test endpoints with curl                             │
│                                                               │
│ Frontend Team:                                                │
│ ├─ [ ] Update baseUrl in app_providers.dart                │
│ ├─ [ ] flutter pub get                                      │
│ ├─ [ ] flutter pub run build_runner build                  │
│ ├─ [ ] flutter run (debug)                                  │
│ └─ [ ] Test all scenarios                                   │
│                                                               │
│ QA Team:                                                      │
│ ├─ [ ] Run full test suite (45+ tests)                      │
│ ├─ [ ] Verify all error scenarios                           │
│ ├─ [ ] Performance testing                                  │
│ ├─ [ ] Memory/CPU profiling                                 │
│ └─ [ ] Sign-off                                             │
│                                                               │
│ Release Team:                                                 │
│ ├─ [ ] Create build (apk/aab)                               │
│ ├─ [ ] Upload to store                                      │
│ ├─ [ ] Monitor metrics                                      │
│ └─ [ ] Handle user feedback                                 │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

---

## Performance Metrics

```
SENSOR COLLECTION
├─ Sampling rate: 50 Hz (20ms intervals)
├─ Window size: 40 samples
├─ Window duration: ~0.8 seconds
└─ Buffer memory: ~1 KB

PREDICTION PIPELINE
├─ Flatten operation: ~1ms
├─ Validation: <1ms
├─ HTTP request overhead: ~10-20ms
├─ Network latency (WiFi): 50-200ms
├─ TFLite inference (backend): 100-200ms
├─ JSON parsing: ~2-5ms
├─ UI update: ~16ms (60 FPS)
└─ **Total E2E: 200-400ms**

THRESHOLDS
├─ Acceptable latency: < 500ms
├─ Warning latency: 500-1000ms
├─ Unacceptable latency: > 1000ms

RESOURCE USAGE
├─ Initial memory: < 100 MB
├─ Growth rate: < 1 MB/minute
├─ CPU during monitoring: < 30%
├─ Network bandwidth: ~5-10 KB per prediction
└─ Battery impact: Minor (sensor dominated, not network)
```


