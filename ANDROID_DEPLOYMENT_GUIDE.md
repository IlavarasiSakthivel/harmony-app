# 🚀 HARmony Android Deployment Guide

Complete step-by-step guide to build and run HARmony on Android devices and emulators.

## Prerequisites

- ✅ Android Studio 2024.1 or newer
- ✅ Android SDK 33+ installed
- ✅ Emulator or physical device with Android 11+
- ✅ Flutter SDK 3.13+ installed
- ✅ 2GB+ free disk space
- ✅ Backend server running locally or on network

## Part 1: Environment Setup

### 1.1 Verify Flutter Installation

```bash
# Check Flutter version
flutter --version

# Check Flutter doctor
flutter doctor

# Expected output should show:
# ✓ Flutter (channel stable)
# ✓ Android toolchain
# ✓ Android Studio
```

If there are issues, fix them:

```bash
# Download Android SDK
flutter pub get
flutter pub upgrade
```

### 1.2 Accept Android Licenses

```bash
# Accept all Android SDK licenses
flutter config --android-studio-dir=/path/to/android-studio

# On Linux/macOS
yes | flutter doctor --android-licenses
```

### 1.3 Get Emulator or Device Ready

**Option A: Using Android Emulator**

```bash
# List available emulators
flutter emulators

# Start an emulator
flutter emulators --launch Pixel_6_API_33

# Or create new one
android create avd -n harmony_avd -k "system-images;android-33;google_apis;arm64-v8a" -c 2G
```

**Option B: Using Physical Device**

```bash
# Enable Developer Mode
# Settings > About > Build number (tap 7 times)
# Settings > Developer Options > USB Debugging ON

# Connect via USB
# Verify connection:
adb devices

# Expected output:
# device_id    device
```

---

## Part 2: Configure Backend Connection

### 2.1 Find Your Backend URL

```bash
# If backend is local:
LOCAL_IP=$(ipconfig getifaddr en0)  # macOS
# or
LOCAL_IP=$(hostname -I | awk '{print $1}')  # Linux
# or
ipconfig  # Windows

echo "Backend URL: http://$LOCAL_IP:8000"
```

### 2.2 Update App Configuration

Edit: `HARmony_Frontend/harmony_app/lib/core/config/app_config.dart`

```dart
class AppConfig {
  // For emulator (connects to host machine's localhost)
  static const String backendBaseUrl = 'http://10.0.2.2:8000';
  
  // For physical device (use your machine's actual IP)
  // static const String backendBaseUrl = 'http://192.168.1.100:8000';
  
  // ... rest of configuration
}
```

### 2.3 Test Backend Connection

```bash
# From emulator or device
adb shell curl http://10.0.2.2:8000/health

# Or use Flutter to test
```

---

## Part 3: Build Setup

### 3.1 Generate Gradle Wrapper

```bash
cd HARmony_Frontend/harmony_app

# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run pub get for Android
cd android
./gradlew wrapper --gradle-version 8.5
cd ..
```

### 3.2 Configure Android Build

Edit: `android/build.gradle`

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 33
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
}
```

### 3.3 Configure Permissions

File: `android/app/src/main/AndroidManifest.xml`

```xml
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.harmony.app">

    <!-- Sensor permissions -->
    <uses-permission android:name="android.permission.ACCESS_ACCELEROMETER" />
    <uses-permission android:name="android.permission.BODY_SENSORS" />
    
    <!-- Network permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- Storage permissions (for Android 11+) -->
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
    
    <!-- Activity recognition (for pedometer) -->
    <uses-permission android:name="android.permission.ACTIVITY_RECOGNITION" />

    <application ...>
        ...
    </application>
</manifest>
```

---

## Part 4: Debug Build & Run

### 4.1 Clean Build for Debug

```bash
cd HARmony_Frontend/harmony_app

# Option 1: Direct run
flutter run

# Option 2: Specify device
flutter run -d emulator-5554

# Option 3: Verbose output for debugging
flutter run -v
```

### 4.2 Monitor Logs

```bash
# Real-time logs
adb logcat | grep flutter

# Or use Flutter's built-in:
flutter logs
```

### 4.3 Common Debug Issues

```bash
# Clear app data
adb shell pm clear com.harmony.app

# Force stop app
adb shell am force-stop com.harmony.app

# Reinstall
adb uninstall com.harmony.app
flutter run
```

---

## Part 5: Release Build

### 5.1 Create Keystore

```bash
# Generate keystore (one-time)
keytool -genkey -v -keystore ~/harmony_key.keystore \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias harmony_key_alias

# You'll be prompted for:
# Keystore password: (set a strong password)
# Key password: (can be same)
# Names and details: (fill in appropriately)
```

### 5.2 Configure Signing

File: `android/key.properties` (create this file)

```properties
storeFile=/Users/username/harmony_key.keystore
storePassword=your_keystore_password
keyAlias=harmony_key_alias
keyPassword=your_key_password
```

**Never commit this file to Git!**

### 5.3 Build Release APK

```bash
cd HARmony_Frontend/harmony_app

# Build APK (one APK for all devices)
flutter build apk --release

# Or build App Bundle (for Play Store)
flutter build appbundle --release

# Output location:
# build/app/outputs/apk/release/app-release.apk
# build/app/outputs/bundle/release/app-release.aab
```

### 5.4 Install Release APK

```bash
# Install on device
adb install build/app/outputs/apk/release/app-release.apk

# Or use Flutter
flutter install -d device_id
```

---

## Part 6: Testing

### 6.1 Pre-deployment Testing Checklist

```bash
# Start backend
cd HARmony_Backend
python run.py

# In another terminal, start app
cd HARmony_Frontend/harmony_app
flutter run

# Test checklist:
```

**Manual Tests:**
- [ ] App starts without crashing
- [ ] Theme toggle works (Settings > Dark Mode)
- [ ] Backend connection is detected (Health check shows ✅)
- [ ] Can collect sensor data (Activity Recognition)
- [ ] Coach screen displays suggestions properly
- [ ] All navigation works
- [ ] No console errors in `flutter logs`

**Automated Tests:**

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

### 6.2 Performance Testing

```bash
# Check memory usage
adb shell dumpsys meminfo com.harmony.app

# Check CPU usage
adb shell top -p $(adb shell pidof com.harmony.app)

# Extract performance metrics
flutter test --profile
```

---

## Part 7: Troubleshooting

### Issue: "Connection timeout to backend"

**Solution:**
```bash
# 1. Verify backend is running
curl http://localhost:8000/health

# 2. Check IP configuration in app_config.dart
# Emulator: use 10.0.2.2 (special alias for host)
# Device: use your actual machine IP

# 3. Test from device:
adb shell curl http://10.0.2.2:8000/health
```

### Issue: "Sensor permission denied"

**Solution:**
```bash
# Grant permissions via adb
adb shell pm grant com.harmony.app android.permission.BODY_SENSORS
adb shell pm grant com.harmony.app android.permission.ACTIVITY_RECOGNITION

# Or let user grant via Settings screen (recommended)
```

### Issue: "TensorFlow Lite model not found"

**Solution:**
```bash
# Check model file exists
ls -la HARmony_Frontend/harmony_app/assets/models/

# Ensure pubspec.yaml includes assets:
# flutter:
#   assets:
#     - assets/models/

# Rebuild
flutter clean && flutter pub get && flutter run
```

### Issue: "App keeps crashing"

**Solution:**
```bash
# Get full stack trace
flutter run -v

# Check Android logs
adb logcat | grep FATAL

# Clear data and reinstall
adb uninstall com.harmony.app
flutter run
```

### Issue: "Build fails with Gradle error"

**Solution:**
```bash
# Update Gradle
cd android
./gradlew wrapper --gradle-version 8.5
cd ..

# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Part 8: Optimization

### 8.1 App Size Optimization

```bash
# Check APK size
flutter build apk --release --split-per-abi

# Outputs:
# app-armeabi-v7a-release.apk (faster on older devices)
# app-arm64-v8a-release.apk (optimized for modern devices)
# app-x86_64-release.apk (for emulators/special cases)
```

### 8.2 Performance Optimization

In `android/app/build.gradle`:

```gradle
android {
    // ...
    
    buildTypes {
        release {
            // Enable code shrinking
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 8.3 Enable R8/ProGuard

File: `android/app/proguard-rules.pro`

```
# Flutter
-keep class io.flutter.** { *; }
-keep class com.google.android.** { *; }

# Tflite
-keep class org.tensorflow.lite.** { *; }

# Keep your app's classes
-keep class com.harmony.app.** { *; }
```

---

## Part 9: Distribution

### 9.1 Google Play Store

1. Create Google Play Console account
2. Add app with Bundle ID: `com.harmony.app`
3. Upload `app-release.aab`
4. Fill in store listing
5. Submit for review

### 9.2 Direct APK Distribution

```bash
# Share APK
adb pull /system/app/app-release.apk

# Users can install via:
adb install app-release.apk

# Or email/WhatsApp/cloud storage
```

---

## Part 10: Continuous Monitoring

### 10.1 Crash Analytics

Add Firebase Crashlytics (optional):

```dart
// In main.dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() {
  // ...
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
  // ...
}
```

### 10.2 Performance Monitoring

```bash
# Check app startup time
flutter run --trace-startup

# Check frame rendering
flutter run --profile
```

---

## Quick Reference Commands

```bash
# Development
flutter run                          # Debug build
flutter run -v                       # Verbose logging
flutter logs                         # Monitor logs

# Building
flutter build apk --release          # Release APK
flutter build appbundle --release    # Play Store Bundle
flutter build apk --split-per-abi    # Size-optimized APKs

# Device/Emulator
adb devices                           # List devices
adb shell                             # Device shell
adb install app-release.apk          # Install APK
adb push/pull                         # File transfer

# Debugging
flutter clean                         # Clean build
flutter pub upgrade                   # Update dependencies
flutter doctor                        # Diagnose issues
```

---

## 📱 Recommended Test Devices

- **Emulator:** Pixel 6 API 33+ (arm64)
- **Physical:** Android 12+ device with Sensors
- **Testing:** Minimum 2GB RAM device

---

## 🎯 Final Checklist Before Release

- [ ] Backend is configured and running
- [ ] All sensors working
- [ ] No console errors
- [ ] Theme toggle working
- [ ] Dark/Light mode switching smooth
- [ ] Coach screen displays properly
- [ ] No memory leaks (`adb shell dumpsys meminfo`)
- [ ] App installs without issues
- [ ] Network connectivity verified
- [ ] Database operations tested
- [ ] Release APK built and tested

---

**For detailed Flutter docs:** https://flutter.dev/docs
**For Android docs:** https://developer.android.com/docs
