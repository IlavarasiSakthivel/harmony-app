# ✅ HARmony Pre-Deployment Verification Checklist

**Use this checklist to verify all components are working before final deployment**

---

## 🗄️ Database Setup

- [ ] PostgreSQL installed and running
  ```bash
  brew services start postgresql@15  # macOS
  sudo systemctl start postgresql      # Linux
  ```

- [ ] Database created successfully
  ```bash
  psql -U harmony_user -d harmony_db
  SELECT 'Database connected!' as status;
  \q
  ```

- [ ] Tables created
  ```bash
  psql -U harmony_user -d harmony_db -c "\dt harmony.*"
  # Should show: activities, sessions, coaching_alerts
  ```

- [ ] Can insert test data
  ```bash
  psql -U harmony_user -d harmony_db -c \
    "INSERT INTO harmony.activities (user_id, activity_name, confidence) 
     VALUES ('test', 'Walking', 0.95);"
  ```

---

## 🔧 Backend Setup

**Virtual Environment:**
- [ ] Virtual environment created
  ```bash
  cd HARmony_Backend
  ls venv/  # Should exist
  ```

- [ ] Virtual environment activated
  ```bash
  source venv/bin/activate
  which python  # Should show venv path
  ```

- [ ] Dependencies installed
  ```bash
  pip list | grep -E "flask|psycopg2|tensorflow"
  # Should show all packages
  ```

**Configuration:**
- [ ] .env file created
  ```bash
  cd HARmony_Backend
  ls .env  # Should exist
  cat .env | grep DATABASE_URL
  # Should show your PostgreSQL URL
  ```

- [ ] Model files present
  ```bash
  ls ml_models/
  # Should show: har_model_fixed.tflite, labels.json
  ```

**Running Backend:**
- [ ] Backend server starts without errors
  ```bash
  python run.py
  # Look for: ✅ HAR Model loaded
  # and: 📊 Server starting... http://0.0.0.0:8000
  ```

- [ ] Health check passes
  ```bash
  curl http://localhost:8000/health
  # Should show: "status": "healthy", "model_loaded": true
  ```

- [ ] Can fetch activities
  ```bash
  curl http://localhost:8000/activities
  # Should return list of activity types
  ```

- [ ] Can fetch model info
  ```bash
  curl http://localhost:8000/model-info
  # Should return expected features and labels
  ```

---

## 📱 Frontend Setup

**Environment:**
- [ ] Flutter installed
  ```bash
  flutter --version
  # Should show version 3.13+
  ```

- [ ] Flutter doctor all green
  ```bash
  flutter doctor
  # ✓ Flutter, ✓ Android toolchain, ✓ Android Studio
  ```

- [ ] Android SDK licensed
  ```bash
  flutter doctor --android-licenses
  ```

**Project Setup:**
- [ ] Dependencies installed
  ```bash
  cd HARmony_Frontend/harmony_app
  flutter pub get
  # Should complete without errors
  ```

- [ ] Configuration updated
  ```bash
  nano lib/core/config/app_config.dart
  # Verify: backendBaseUrl = 'http://10.0.2.2:8000' (emulator)
  # or your machine IP for physical device
  ```

- [ ] Build files generated
  ```bash
  flutter clean
  flutter pub get
  # Should complete successfully
  ```

---

## 📲 Device/Emulator Setup

**Android Emulator:**
- [ ] Emulator available
  ```bash
  flutter emulators
  # Should show at least one emulator
  ```

- [ ] Emulator launches
  ```bash
  flutter emulators --launch Pixel_6_API_33
  # Wait for it to fully boot
  ```

- [ ] Can connect to emulator
  ```bash
  adb devices
  # Should show: emulator-5554    device
  ```

**Physical Device:**
- [ ] USB Debugging enabled
  - Settings > About phone > Tap Build number 7 times
  - Settings > Developer Options > USB Debugging ON

- [ ] Device connects via ADB
  ```bash
  adb devices
  # Should show: device_id    device
  ```

- [ ] Device has required permissions
  ```bash
  adb shell pm list permissions | grep SENSORS
  # Should show permission available
  ```

---

## 🚀 App Launch & Runtime

**Debug Build:**
- [ ] App builds successfully
  ```bash
  cd HARmony_Frontend/harmony_app
  flutter run
  # Should show: Launching app... ✓ Installed successfully
  ```

- [ ] App launches without crashing
  - Should see HARmony splash screen
  - Then home screen loads

- [ ] Console shows no errors
  ```bash
  flutter logs
  # Should NOT see: ERROR, FATAL, Exception
  ```

**App Features:**
- [ ] Home screen displays
  - [ ] Bottom navigation visible
  - [ ] Cards render properly
  - [ ] No layout overflow

- [ ] Activity Recognition working
  - [ ] Can open Realtime Recognition tab
  - [ ] See sensor data being collected
  - [ ] Activity predictions showing

- [ ] Settings screen accessible
  - [ ] Can navigate to Settings
  - [ ] Settings load without crash

- [ ] Dark Mode works
  - [ ] Settings > Dark Mode toggle appears
  - [ ] Toggle switches theme instantly
  - [ ] Colors change correctly (light/dark)
  - [ ] Theme persists after app restart

- [ ] Coach screen functional
  - [ ] Navigate to Coach tab
  - [ ] See current activity
  - [ ] Suggestions displayed
  - [ ] Goal tracker visible

---

## 🔌 Backend-Frontend Integration

**Connection Test:**
- [ ] Backend responding
  ```bash
  # In another terminal, backend should be running
  curl http://localhost:8000/health
  # Response: successful (200 OK)
  ```

- [ ] App detects backend
  - In app settings, should show backend status
  - Should show ✅ Connected

- [ ] Can make predictions
  - App sensors collecting data
  - Backend model making predictions
  - Results displayed in real-time

**Network Features:**
- [ ] API calls complete without timeout
  - Check `flutter logs` for timing
  - Should see successful requests

- [ ] Error handling working
  - Temporarily disconnect backend
  - App should show error gracefully
  - No crashes or freezes

---

## 💾 Database Integration

**Data Storage:**
- [ ] Activities being stored
  ```bash
  psql -U harmony_user -d harmony_db
  SELECT COUNT(*) FROM harmony.activities;
  # Should be > 0 after using app
  ```

- [ ] Sessions being recorded
  ```bash
  SELECT * FROM harmony.sessions ORDER BY start_time DESC LIMIT 5;
  # Should have recent sessions
  ```

- [ ] Coaching alerts saved
  ```bash
  SELECT * FROM harmony.coaching_alerts ORDER BY timestamp DESC LIMIT 5;
  # Should have recent alerts
  ```

---

## 📊 Performance Validation

**App Performance:**
- [ ] App load time < 5 seconds
  ```bash
  # Observe startup time in flutter logs
  ```

- [ ] Memory usage reasonable
  ```bash
  adb shell dumpsys meminfo com.harmony.app | head -20
  # RAM usage should be < 300 MB
  ```

- [ ] No memory leaks
  ```bash
  # Use app for 5 minutes, then close
  # Memory should release back to system
  ```

- [ ] Smooth scrolling
  - All screens should scroll smoothly
  - No frame drops or stuttering

- [ ] Theme switch is instant
  - Dark mode toggle should be immediate
  - No loading delays

---

## 🔐 Permissions

**Sensor Permissions:**
- [ ] Accelerometer permission granted
  - Sensors should work in app

- [ ] Storage permission granted
  - Data export should work

- [ ] Network permission active
  - Backend communication works

---

## 📈 Build & Deployment

**Debug APK:**
- [ ] Debug APK builds
  ```bash
  flutter build apk
  # Should complete successfully
  # Output: build/app/outputs/apk/debug/app-debug.apk
  ```

**Release APK:**
- [ ] Release APK builds
  ```bash
  flutter build apk --release
  # Should complete successfully
  # Output: build/app/outputs/apk/release/app-release.apk
  ```

- [ ] Release APK installs
  ```bash
  adb install build/app/outputs/apk/release/app-release.apk
  # Should complete: Success
  ```

- [ ] Release app works
  - Behaviors identicalto debug build
  - All features working
  - No crashes

- [ ] Size optimized
  ```bash
  ls -lh build/app/outputs/apk/release/
  # Normal: 20-40 MB per ABI
  ```

---

## 🧪 Integration Tests

**Complete Flow Test:**

1. **Startup:**
   - [ ] App launches
   - [ ] Permissions requested (if needed)
   - [ ] Database initializes
   - [ ] Backend connects
   - [ ] Model loaded

2. **Runtime:**
   - [ ] Sensors activated
   - [ ] Data collected continuously
   - [ ] Predictions real-time
   - [ ] UI responsive

3. **Persistence:**
   - [ ] Data saved to PostgreSQL
   - [ ] Theme preference saved
   - [ ] Settings retained after restart

4. **Functionality:**
   - [ ] All tabs working
   - [ ] Navigation smooth
   - [ ] No crashes for 5+ minutes usage

5. **Network Resilience:**
   - [ ] App handles backend down gracefully
   - [ ] Reconnects when backend up again
   - [ ] No data loss

---

## 🆘 Troubleshooting

**If any check fails:**

1. **App won't start:**
   ```bash
   flutter clean
   flutter pub get
   flutter run -v
   # Check full error in verbose output
   ```

2. **Backend won't connect:**
   ```bash
   curl http://localhost:8000/health
   # If fails, backend not running
   python run.py  # Start it
   ```

3. **Database connection error:**
   ```bash
   psql -U harmony_user -d harmony_db
   # If fails, database setup incomplete
   bash setup_postgres.sh  # Redo setup
   ```

4. **Theme not changing:**
   ```bash
   flutter logs | grep theme
   # Check for errors related to theme provider
   ```

5. **Sensors not working:**
   ```bash
   adb shell pm grant com.harmony.app android.permission.BODY_SENSORS
   ```

---

## 📋 Final Sign-Off

Once all items are checked:

- [ ] All database checks passed
- [ ] All backend checks passed
- [ ] All frontend checks passed
- [ ] All device setup checks passed
- [ ] All app launch checks passed
- [ ] All integration checks passed
- [ ] All performance checks passed
- [ ] All deployment checks passed

**System Status: ✅ READY FOR DEPLOYMENT**

---

## 🎯 Next Steps

1. **For Testing:** Share APK with testers
2. **For Production:** Upload to Google Play Store
3. **For Distribution:** Email or cloud share APK
4. **For Updates:** Increment version and rebuild

---

## 📞 Quick Support

| Issue | Quick Fix |
|-------|-----------|
| App crashes | `flutter clean && flutter run` |
| Backend unreachable | `python run.py` in HARmony_Backend |
| DB connection error | `bash setup_postgres.sh` |
| Theme not working | `flutter logs \| grep theme` |
| Sensors disabled | Grant permissions in Settings |

---

**If all checks pass, your HARmony app is production-ready! 🎉**
