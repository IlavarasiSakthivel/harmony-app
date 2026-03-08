# QA Test Plan: TFLite Backend Integration

## Pre-Testing Setup

### Requirements
- Backend server running at `http://localhost:8000` (or configured URL)
- `har_model_fixed.tflite` loaded on backend
- `labels.json` available on backend
- Frontend build: `flutter run` or `flutter build apk`
- Test device with accelerometer/gyroscope sensors

### Test Data
Use any normal device activity (walking, running, sitting, standing, cycling) or simulated sensor data.

---

## Test Suite 1: Backend Health Check

### TC1.1: Backend Available & Model Loaded
**Precondition:** Backend running with model loaded
**Steps:**
1. Launch app
2. Look at AppBar top-right

**Expected Result:**
- ✅ Green dot indicator visible
- ✅ Status message: "Backend ready - Ready to start"
- ✅ "Start Monitoring" button enabled (not grayed out)
- ✅ Hover tooltip shows: "Backend model loaded"

**Actual Result:** [Fill during testing]

---

### TC1.2: Backend Running, Model Not Loaded
**Precondition:** Backend running, model not loaded on startup
**Steps:**
1. Ensure backend `/health` returns `"model_loaded": false`
2. Launch app
3. Observe status indicators

**Expected Result:**
- ✅ Red dot indicator in AppBar
- ✅ Status message: "Model not loaded on server. Please check model deployment/runtime."
- ✅ "Start Monitoring" button disabled (grayed out)
- ✅ Error banner shows red background
- ✅ "Retry" button available in error banner

**Actual Result:** [Fill during testing]

---

### TC1.3: Backend Unavailable
**Precondition:** Backend server not running or unreachable
**Steps:**
1. Stop backend server
2. Launch app or navigate to Real-time screen
3. Wait for health check timeout

**Expected Result:**
- ✅ Red dot indicator in AppBar
- ✅ Status message: "Cannot connect to backend: ..."
- ✅ "Start Monitoring" button disabled
- ✅ Connection timeout after ~5 seconds
- ✅ Retry button available

**Actual Result:** [Fill during testing]

---

### TC1.4: Manual Health Check Retry
**Precondition:** Backend was unavailable, now restart backend
**Steps:**
1. From error state (TC1.3), click "Retry" button
2. Observe status update

**Expected Result:**
- ✅ Status checks `/health` endpoint again
- ✅ If model loaded: indicators turn green, button enabled
- ✅ If model not loaded: remains red/disabled
- ✅ Status message updates accordingly

**Actual Result:** [Fill during testing]

---

## Test Suite 2: Sensor Data Collection & Windowing

### TC2.1: Sensor Window Progress Display
**Precondition:** Backend healthy, app on Real-time screen, not monitoring
**Steps:**
1. Click "Start Monitoring"
2. Observe "INPUT WINDOW" widget
3. Watch for ~1.5 seconds (should collect ~75 samples at 50Hz, but only need 40)

**Expected Result:**
- ✅ "INPUT WINDOW" shows "0/40 samples" initially
- ✅ Progress bar shows 0%
- ✅ Samples increment: "1/40", "2/40", ..., "40/40"
- ✅ Progress bar grows proportionally
- ✅ Color changes to green when reaches "40/40"
- ✅ Border color changes from blue to green at 40/40

**Actual Result:** [Fill during testing]

---

### TC2.2: Window Reset After Prediction
**Precondition:** TC2.1 complete (40/40 reached)
**Steps:**
1. Continue monitoring and observe multiple windows
2. First prediction received → "40/40" shows
3. Wait for next window collection (~0.8 seconds)
4. Observe progress reset

**Expected Result:**
- ✅ After first prediction, window progress resets
- ✅ Starts collecting next 40 samples
- ✅ Progress goes back to low count (0-10/40)
- ✅ Multiple predictions received over time
- ✅ Window collection continuous while monitoring

**Actual Result:** [Fill during testing]

---

### TC2.3: Sensor Data Validation (Client-Side)
**Precondition:** Backend running, monitoring started
**Steps:**
1. Artificially break sensor data collection (e.g., modify `sensor_service.dart` to use 90 samples)
2. Attempt to trigger prediction
3. Observe validation

**Expected Result:**
- ✅ Client-side check catches invalid length
- ✅ Request blocked from being sent
- ✅ Error shown: "Need exactly 120 sensor values (40x3)."
- ✅ No network call to `/predict` made
- ✅ Monitoring does not crash

**Actual Result:** [Fill during testing]

---

## Test Suite 3: Prediction Request/Response

### TC3.1: Valid Prediction (Happy Path)
**Precondition:** Backend healthy, monitoring started, 40 samples collected
**Steps:**
1. Perform activity (walk, run, sit, etc.) while monitoring
2. Let sensor window fill to 40/40
3. Observe prediction

**Expected Result:**
- ✅ Prediction received within ~300-400ms
- ✅ "CURRENT ACTIVITY" card updates with activity name
- ✅ Confidence score displays (e.g., "95%")
- ✅ Confidence progress bar fills proportionally
- ✅ Color changes based on confidence:
  - Green: ≥ 80%
  - Amber: 60-79%
  - Red: < 60%
- ✅ Top probabilities displayed (if backend returns `all_probabilities`)
- ✅ Prediction added to history list

**Actual Result:** [Fill during testing]

---

### TC3.2: Prediction Response with Probabilities
**Precondition:** Backend returns `all_probabilities` in response
**Steps:**
1. Receive prediction with probabilities
2. Look at prediction result section

**Expected Result:**
- ✅ "TOP PROBABILITIES" section visible
- ✅ Top 5 activities listed (sorted by probability)
- ✅ Each activity shows:
  - Activity name
  - Horizontal progress bar
  - Percentage (0-100%)
- ✅ Bars proportional to probability values
- ✅ Layout clean and readable

**Actual Result:** [Fill during testing]

---

### TC3.3: Multiple Consecutive Predictions
**Precondition:** Monitoring active, getting predictions
**Steps:**
1. Continue monitoring for 10+ seconds
2. Generate multiple windows and predictions
3. Observe prediction history

**Expected Result:**
- ✅ Each prediction added to history list
- ✅ Newest prediction at top of list
- ✅ History shows activity, timestamp, confidence
- ✅ List scrollable if > 10 predictions
- ✅ Old predictions disappear after 10 entries
- ✅ No memory leaks or crashes

**Actual Result:** [Fill during testing]

---

## Test Suite 4: Error Handling

### TC4.1: Backend Returns 400 (Invalid Data)
**Precondition:** Backend configured to reject data < 120 values
**Steps:**
1. Modify frontend to send 90 values instead of 120
2. Start monitoring
3. Observe error

**Expected Result:**
- ✅ Error caught by client validation first (prevents sending)
- ✅ If somehow sent: 400 response received
- ✅ Error message: "Need exactly 120 sensor values (40x3)."
- ✅ Monitoring continues (doesn't stop)
- ✅ Next window retries

**Actual Result:** [Fill during testing]

---

### TC4.2: Backend Returns 503 (Model Not Ready)
**Precondition:** Backend running but model loading/unloaded during prediction
**Steps:**
1. Start monitoring
2. While monitoring, unload model on backend (or simulate 503)
3. Let next prediction attempt fail

**Expected Result:**
- ✅ Prediction fails with 503 error
- ✅ Error snackbar shows: "Model not loaded on server..."
- ✅ Status indicator turns red
- ✅ Monitoring continues (doesn't auto-stop)
- ✅ User can retry or stop manually
- ✅ Next window retries prediction

**Actual Result:** [Fill during testing]

---

### TC4.3: Network Timeout (8 Seconds)
**Precondition:** Network latency > 8 seconds or backend hanging
**Steps:**
1. Simulate slow network (throttle to very slow)
2. Start monitoring
3. Let timeout trigger

**Expected Result:**
- ✅ After 8 seconds, request times out
- ✅ Error snackbar shown
- ✅ Monitoring continues
- ✅ Next window retries with normal timeout
- ✅ App doesn't freeze or crash

**Actual Result:** [Fill during testing]

---

### TC4.4: Intermittent Errors & Recovery
**Precondition:** Network occasionally fails
**Steps:**
1. Simulate flaky network (drops 1/5 requests)
2. Start monitoring
3. Let multiple windows fail and succeed intermittently

**Expected Result:**
- ✅ Failed predictions show error snackbar
- ✅ Successful predictions show result
- ✅ No crash or hung state
- ✅ Status indicators update correctly
- ✅ User can stop/reset at any time

**Actual Result:** [Fill during testing]

---

## Test Suite 5: User Interface & Control

### TC5.1: Start/Stop Monitoring
**Precondition:** Backend healthy, Real-time screen open
**Steps:**
1. Click "Start Monitoring"
2. Observe state changes
3. Click "Stop"
4. Observe state changes

**Expected Result:**
- ✅ Start button disabled while monitoring
- ✅ Stop button enabled while monitoring
- ✅ Sensor data collection starts (accelerometer chart updates)
- ✅ Window progress shows
- ✅ Predictions begin after first 40 samples
- ✅ Stop button stops monitoring
- ✅ Predictions stop
- ✅ Sensor chart stops updating

**Actual Result:** [Fill during testing]

---

### TC5.2: Reset Session
**Precondition:** Monitoring complete or in progress
**Steps:**
1. Click "Reset Session"
2. Observe state

**Expected Result:**
- ✅ Activity resets to "Unknown"
- ✅ Confidence resets to 0%
- ✅ Prediction count resets
- ✅ Prediction history cleared
- ✅ Sensor chart cleared
- ✅ Monitoring stops (if running)
- ✅ All counters reset
- ✅ Status message updates

**Actual Result:** [Fill during testing]

---

### TC5.3: Disable Start When Backend Unhealthy
**Precondition:** Backend unavailable or model not loaded
**Steps:**
1. Observe "Start Monitoring" button state
2. Try to click it

**Expected Result:**
- ✅ Button appears grayed out/disabled
- ✅ Click does nothing
- ✅ Error banner shows reason
- ✅ "Retry" button available
- ✅ Clicking retry updates status
- ✅ If backend recovers, button enables

**Actual Result:** [Fill during testing]

---

### TC5.4: Accelerometer Chart Display
**Precondition:** Monitoring in progress
**Steps:**
1. Perform various movements (shake phone, walk, stand still)
2. Observe accelerometer chart in real-time

**Expected Result:**
- ✅ Chart shows X, Y, Z axes (blue, green, amber)
- ✅ Lines animate smoothly
- ✅ Chart updates continuously
- ✅ Axis values shown below chart
- ✅ Scale auto-adjusts to data range
- ✅ No lag or stuttering

**Actual Result:** [Fill during testing]

---

## Test Suite 6: Label Rendering

### TC6.1: Dynamic Labels from Backend
**Precondition:** Backend returns `activity_labels` in `/model-info`
**Steps:**
1. Check backend `/model-info` response
2. Verify labels loaded in app
3. Check prediction results display

**Expected Result:**
- ✅ Activity labels fetched from `/model-info`
- ✅ Not hardcoded (e.g., "Walking", "Running", etc. from backend)
- ✅ Prediction activity matches one of fetched labels
- ✅ Labels update if backend labels change (on next health check)
- ✅ Custom labels work (not just standard HAR activities)

**Actual Result:** [Fill during testing]

---

### TC6.2: Activity Color Coding
**Precondition:** Predictions received
**Steps:**
1. Receive predictions for different activities
2. Observe color coding in history

**Expected Result:**
- ✅ Each activity has consistent color
- ✅ History dots/badges color-coded by activity
- ✅ Standard mapping (e.g., Walking=blue, Running=green)
- ✅ Unknown activity has gray color
- ✅ Colors are distinguishable

**Actual Result:** [Fill during testing]

---

## Test Suite 7: Data Persistence & State

### TC7.1: Session Saving
**Precondition:** Monitoring complete with predictions
**Steps:**
1. Monitor for 10+ seconds with predictions
2. Click Stop
3. Check if session saved to history
4. Navigate away and back

**Expected Result:**
- ✅ Session saved to local database
- ✅ Session appears in History screen
- ✅ Predictions preserved
- ✅ Duration, start/end times correct
- ✅ Summary activity accurate

**Actual Result:** [Fill during testing]

---

### TC7.2: Activity History Display
**Precondition:** Predictions received during monitoring
**Steps:**
1. Observe "Recent Predictions" section
2. Monitor long enough for 5+ predictions

**Expected Result:**
- ✅ Latest predictions shown at top
- ✅ History shows: activity, timestamp, confidence
- ✅ Timestamps accurate to current time
- ✅ Predictions sorted newest first
- ✅ Scrollable if > 10 items
- ✅ Confidence values display correctly

**Actual Result:** [Fill during testing]

---

## Test Suite 8: Edge Cases

### TC8.1: Rapid Start/Stop
**Precondition:** Backend healthy
**Steps:**
1. Click "Start Monitoring"
2. Immediately click "Stop"
3. Immediately click "Start" again
4. Repeat 5 times rapidly

**Expected Result:**
- ✅ No crashes
- ✅ No memory leaks
- ✅ No stuck states
- ✅ Sensors properly released on stop
- ✅ New session initializes cleanly on start

**Actual Result:** [Fill during testing]

---

### TC8.2: Monitoring During Network Change
**Precondition:** Monitoring in progress on WiFi
**Steps:**
1. Monitor on WiFi
2. Switch to mobile data (or vice versa)
3. Continue monitoring

**Expected Result:**
- ✅ Monitoring continues smoothly
- ✅ Slight latency change observed
- ✅ No crashes or disconnection
- ✅ Predictions resume on new network

**Actual Result:** [Fill during testing]

---

### TC8.3: Screen Rotation During Monitoring
**Precondition:** Monitoring in progress
**Steps:**
1. Start monitoring
2. Rotate device (portrait ↔ landscape)

**Expected Result:**
- ✅ UI re-layouts correctly
- ✅ Monitoring continues uninterrupted
- ✅ Charts and progress widgets adjust size
- ✅ No data loss or reset
- ✅ No crashes

**Actual Result:** [Fill during testing]

---

### TC8.4: App Background/Foreground
**Precondition:** Monitoring in progress
**Steps:**
1. Start monitoring
2. Send app to background
3. Wait 5 seconds
4. Bring app to foreground

**Expected Result:**
- ✅ Sensors stop when backgrounded (or configured behavior)
- ✅ Monitoring state preserved
- ✅ No crashes when returning
- ✅ Can resume monitoring
- ✅ Activity not lost

**Actual Result:** [Fill during testing]

---

## Test Suite 9: Performance

### TC9.1: Prediction Latency
**Precondition:** Backend healthy, monitoring in progress
**Steps:**
1. Measure time from window-ready (40/40) to result display
2. Repeat 10 times, record latencies
3. Calculate average

**Expected Result:**
- ✅ Average latency: 200-400ms
- ✅ 95th percentile: < 500ms
- ✅ No latency > 1000ms
- ✅ Consistent performance (not degrading)

**Actual Result:** [Fill during testing]
**Latencies recorded:**
- Min: ___ ms
- Max: ___ ms
- Avg: ___ ms

---

### TC9.2: Memory Usage
**Precondition:** Monitoring for extended period
**Steps:**
1. Monitor memory usage (via Android Studio Profiler)
2. Run monitoring for 5+ minutes
3. Observe memory growth

**Expected Result:**
- ✅ Initial memory: < 100 MB
- ✅ Growth rate: < 1 MB/minute
- ✅ No unbounded growth
- ✅ Memory stable after 2 minutes
- ✅ Reset/clear releases memory

**Actual Result:** [Fill during testing]

---

### TC9.3: CPU Usage
**Precondition:** Monitoring in progress
**Steps:**
1. Monitor CPU usage
2. Run for 1 minute continuous activity
3. Measure

**Expected Result:**
- ✅ CPU < 30% during monitoring
- ✅ Dominated by sensor collection, not network
- ✅ Smooth animation (60 FPS on charts)
- ✅ UI responsive to input

**Actual Result:** [Fill during testing]

---

## Summary & Sign-Off

### Test Environment
- Device: ________________
- OS Version: ________________
- App Version: ________________
- Backend URL: ________________
- Date: ________________

### Results Summary
- Total Tests: 45+
- Passed: ____
- Failed: ____
- Skipped: ____

### Failed Tests
(List any failures here with details)
1. TC#: __________________
   Issue: __________________
   Severity: [Critical / High / Medium / Low]

### Recommendations
(Any improvements or issues for dev team)

---

### QA Sign-Off
- Tester: ________________
- Date: ________________
- Status: [✅ PASS / ⚠️ PASS WITH ISSUES / ❌ FAIL]

---

## Notes

- Keep this test plan updated as new features are added
- Rerun full suite before each release
- Use real devices when possible (not just emulator)
- Test on different network conditions (WiFi, 4G, slow/flaky)
- Performance tests can be automated with cloud testing tools

