# HARmony Flutter App - Deployment & Running Guide

## 🎯 Overview
This guide provides all commands and instructions to run the HARmony Flutter app on multiple platforms.

---

## 📱 Prerequisites

### System Requirements
- Flutter SDK (>=3.8.0)
- Android SDK (API level 26+) 
- Dart SDK (>=3.8.0)
- Git
- Python 3.8+ (for FastAPI backend)

### Environment Setup
```bash
# Verify Flutter installation
flutter --version

# Verify device connectivity
flutter devices

# Get dependencies
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app
flutter pub get
```

---

## 🚀 RUNNING ON ANDROID DEVICE (Your V2322 Phone)

### Step 1: Connect USB Device
1. Plug in your Android device via USB
2. Enable USB Debugging on device:
   - Settings → Developer Options → USB Debugging (Enable)
   - Allow USB debugging on the computer when prompted

### Step 2: Verify Device Detection
```bash
flutter devices
# Should show: V2322 (mobile) • 10AE1M17C2001RX • android-arm64 • Android 15 (API 35)
```

### Step 3: Run App on Physical Device
```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app

# Run in debug mode (fastest)
flutter run -d V2322

# Run in release mode (optimized, for production testing)
flutter run -d V2322 --release

# Run with verbose logging
flutter run -d V2322 -v
```

### Step 4: Stop the App
Press `q` in the terminal or `Ctrl+C`

---

## 🖥️ RUNNING ON ANDROID EMULATOR

### Step 1: Check Available Emulators
```bash
flutter emulators
# List all available emulators
```

### Step 2: Launch an Emulator
```bash
# If you have an emulator installed, launch it
flutter emulators --launch <emulator_name>

# Example:
flutter emulators --launch pixel_6
```

### Step 3: Run App on Emulator
```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app

# Run in debug mode
flutter run

# Run with specific device
flutter run -d <emulator_id>

# Get emulator ID
adb devices
```

---

## 🖲️ RUNNING ON LINUX DESKTOP

### Step 1: Verify Linux Support
```bash
flutter config --enable-linux-desktop
flutter doctor
```

### Step 2: Run on Linux
```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app

# Run debug build
flutter run -d linux

# Run release build
flutter build linux --release
./build/linux/x64/release/bundle/harmony_app
```

---

## 🌐 RUNNING ON WEB

### Step 1: Enable Web Support
```bash
flutter config --enable-web
flutter doctor
```

### Step 2: Run Web App
```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app

# Run in debug mode (with hot reload)
flutter run -d chrome

# Run on Firefox
flutter run -d firefox

# Run on Safari (macOS only)
flutter run -d safari

# Build for production
flutter build web --release

# The build output will be in: build/web/
```

### Step 3: Serve Web App
```bash
# If you have Python installed
cd build/web
python -m http.server 8080

# Then open: http://localhost:8080
```

---

## 🔧 BACKEND SETUP (FastAPI)

### Step 1: Start the Backend Server
```bash
# Navigate to backend directory (adjust path as needed)
cd /path/to/backend

# Install Python dependencies
pip install -r requirements.txt

# Run the FastAPI server
python main.py

# Server should start on: http://localhost:8000
# API Docs: http://localhost:8000/docs
```

### Important: Backend Configuration
- The app is configured to connect to `http://localhost:8002/docs` for API endpoints
- If your backend runs on a different port or host, update the API service:
  - File: `lib/features/activity_recognition/services/api_service.dart`
  - Change: `final String baseUrl;` constructor parameter or default value

### API Endpoints Used by App
The app expects these endpoints from your FastAPI backend:
- `POST /api/predict` - Activity prediction
- `GET /api/activities` - Fetch recorded activities
- `GET /api/diagnostics/quick-tests/count` - Quick test count
- `GET /api/coach/insights` - Coach recommendations
- `GET /api/analytics/summary?range={range}` - Analytics data
- `GET /api/health/snapshot?date={date}` - Health metrics
- `GET /api/model/insights` - Model information
- `GET /api/timeline?date={date}` - Activity timeline

---

## 📦 BUILD COMMANDS

### Build APK for Android (Debug)
```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app

flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Build APK for Android (Release)
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Build AAB for Google Play Store
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Build Linux Desktop App
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

### Build Web App
```bash
flutter build web --release
# Output: build/web/
```

---

## 🐛 TROUBLESHOOTING

### Issue: App won't start on physical device
```bash
# Check device connection
adb devices

# Clear app cache
adb shell pm clear com.example.harmony_app_new

# Restart device
adb reboot
```

### Issue: "Device not found"
```bash
# List all available devices
flutter devices

# Restart Flutter daemon
flutter clean
flutter pub get
flutter devices
```

### Issue: Port 8002 already in use (Backend)
```bash
# Kill process on port 8002
lsof -i :8002
kill -9 <PID>

# Or run backend on different port and update app configuration
```

### Issue: Hot reload not working
```bash
# Use hot restart instead
r (refresh/hot reload)
R (full restart)

# Or rebuild
flutter clean
flutter pub get
flutter run -d V2322
```

### Issue: Build fails with "error: undefined symbol"
```bash
flutter clean
flutter pub get
flutter pub run build_runner build  # If using code generation
flutter run -d V2322
```

---

## 🎨 THEME CONFIGURATION

The app uses **Dark Mode by Default**. To change:
- File: `lib/main.dart`
- Change: `themeMode: ThemeMode.dark` to `ThemeMode.light` or `ThemeMode.system`

---

## 📊 APP FEATURES CHECKLIST

✅ Real-time Activity Recognition
✅ History/Recorded Activities (from API)
✅ Diagnostic Screen with Quick Test Count
✅ Coach Insights
✅ Analytics Dashboard
✅ Health Monitoring
✅ Timeline View
✅ Academic Insights
✅ Profile Management
✅ Settings & Preferences
✅ Dark Mode (Default)
✅ Offline Support (with local SQLite cache)

---

## 🔐 SECURITY NOTES

1. The app includes internet permission in AndroidManifest.xml
2. Sensor permissions (accelerometer, gyroscope) are required
3. Location permissions are optional
4. All API calls include timeout handling (8 seconds default)
5. Fallback to mock data when backend is unavailable

---

## 📱 DEVICE-SPECIFIC NOTES

### Android Device (V2322)
- **Model**: Android 15 (API 35)
- **Architecture**: ARM64
- **USB Debugging**: Must be enabled
- **Developer Options**: Must be enabled
- **Storage**: Ensure at least 500MB free space

### Android Emulator
- **Minimum API**: 26
- **Recommended API**: 31+
- **RAM**: 2GB minimum
- **Storage**: 1GB minimum

### Linux Desktop
- **Desktop Support**: Enabled via Flutter config
- **GTK**: Required (usually pre-installed)
- **OpenGL**: Required for graphics

### Web Browser
- **Chrome**: Recommended (best support)
- **Firefox**: Supported
- **Safari**: Supported (macOS only)
- **Edge**: Supported

---

## 🚀 QUICK START COMMAND

Run this to start everything:

```bash
# Terminal 1: Start Backend
cd /path/to/backend
python main.py

# Terminal 2: Run App on Physical Device
cd /home/ilavarasi/Documents/Final_Project/HARmony_Frontend/harmony_app
flutter run -d V2322

# Terminal 3 (Optional): Monitor logs
adb logcat | grep flutter
```

---

## 📝 NOTES FOR PRODUCTION

1. **Update versionCode and versionName** in `pubspec.yaml` before release
2. **Sign APK**: Follow Android documentation for keystore signing
3. **Test on Multiple Devices**: Test on at least 3 different Android versions
4. **Optimize Build Size**: Use `--split-per-abi` for separate APKs
5. **Backend URL**: Update to production server URL before release
6. **Error Logging**: Add crash reporting (Firebase Crashlytics recommended)

---

## 📞 SUPPORT

For issues or questions:
1. Check Flutter Doctor: `flutter doctor`
2. Check device logs: `adb logcat`
3. Check app logs: `flutter logs`
4. Enable verbose mode: `flutter run -v`

---

**Last Updated**: February 20, 2026
**App Version**: 1.0.0
**Flutter Version**: 3.8.0+
**Min Android API**: 26
**Min iOS Version**: 12.0

