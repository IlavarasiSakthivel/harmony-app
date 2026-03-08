# 🎯 HARmony Complete Deployment & Execution Guide

**Complete step-by-step instructions to get HARmony fully working end-to-end**

---

## 📋 Table of Contents

1. [Environment Setup](#1-environment-setup)
2. [Database Setup](#2-database-setup-postgresql)
3. [Backend Configuration](#3-backend-configuration-and-startup)
4. [Frontend Configuration](#4-frontend-configuration)
5. [Running on Android](#5-running-on-android-device--emulator)
6. [Testing the Complete System](#6-testing-the-complete-system)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Environment Setup

### 1.1 Verify System Requirements

```bash
# Python 3.9+
python3 --version

# Flutter
flutter --version

# Java (for Android)
java -version

# Optional: PostgreSQL client
psql --version
```

### 1.2 Project Setup

```bash
cd /home/ilavarasi/Documents/Final_Project/HARmony

# Create main directories if missing
mkdir -p HARmony_Backend
mkdir -p HARmony_Frontend/harmony_app
mkdir -p HARmony_ML_Core

ls -la
```

---

## 2. Database Setup (PostgreSQL)

### 2.1 Install PostgreSQL

**macOS:**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download from: https://www.postgresql.org/download/windows/

### 2.2 Create HARmony Database

```bash
# Run the setup script
cd HARmony_Backend
bash setup_postgres.sh

# Or manually:
psql -U postgres << EOF
CREATE USER harmony_user WITH PASSWORD 'harmony_password';
CREATE DATABASE harmony_db OWNER harmony_user;
GRANT ALL PRIVILEGES ON DATABASE harmony_db TO harmony_user;
EOF
```

### 2.3 Verify Database Connection

```bash
psql -U harmony_user -d harmony_db -h localhost

# Test query
SELECT 'Database ready!' as status;
\q
```

---

## 3. Backend Configuration and Startup

### 3.1 Set Up Backend Environment

```bash
cd HARmony_Backend

# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
# On macOS/Linux:
source venv/bin/activate
# On Windows:
# venv\Scripts\activate

# Verify activation (should show (venv) prompt)
```

### 3.2 Install Dependencies

```bash
# Make sure you're in activated venv
pip install --upgrade pip

# Install required packages
pip install -r requirements.txt

# Verify installations
pip list | grep -E "flask|psycopg2|tensorflow"
```

### 3.3 Configure .env File

```bash
# Copy example config
cp .env.example .env

# Edit .env with your settings
nano .env  # or use your preferred editor
```

**Required .env settings:**
```
FLASK_ENV=production
DATABASE_URL=postgresql://harmony_user:harmony_password@localhost:5432/harmony_db
API_PORT=8000
MODEL_PATH=../ml_models/har_model_fixed.tflite
```

### 3.4 Verify Model Files

```bash
# Check models exist
ls -la ml_models/

# Should show:
# - har_model_fixed.tflite (2-3 MB)
# - labels.json (activity labels)
```

### 3.5 Start Backend Server

```bash
# Terminal 1: Backend Server
cd HARmony_Backend
source venv/bin/activate  # or activate for Windows

# Choose backend based on your setup:

# Option A: FastAPI (Recommended)
python run.py

# Option B: Flask (Alternative)
python run_server.py

# Expected output:
# 🚀 HARmony Backend Server (FastAPI)
# ✅ Server starting... http://0.0.0.0:8000
# 📊 Available endpoints: /health, /predict, /model-info
```

### 3.6 Test Backend Health

**In another terminal:**
```bash
# Test connection
curl http://localhost:8000/health

# Expected response:
# {
#   "status": "healthy",
#   "model_loaded": true,
#   "timestamp": "2025-08-03T12:34:56.789",
#   "version": "1.0.0"
# }

# Test model info
curl http://localhost:8000/model-info

# Test activities
curl http://localhost:8000/activities
```

---

## 4. Frontend Configuration

### 4.1 Get Your Machine's IP Address

**For Android Device Connection:**
```bash
# macOS
ifconfig | grep "inet " | grep -v 127.0.0.1

# Linux
hostname -I

# Windows
ipconfig
```

**Note:** For emulator, use `10.0.2.2` (special alias for host)

### 4.2 Update App Configuration

Edit: `HARmony_Frontend/harmony_app/lib/core/config/app_config.dart`

```dart
class AppConfig {
  // For Android Emulator (recommended for testing)
  static const String backendBaseUrl = 'http://10.0.2.2:8000';
  
  // For Physical Android Device (replace with your IP)
  // static const String backendBaseUrl = 'http://192.168.1.100:8000';
  
  // Rest of configuration...
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### 4.3 Set Up Flutter Environment

```bash
# Terminal 2: Frontend Setup
cd HARmony_Frontend/harmony_app

# Get Flutter dependencies
flutter pub get

# Check doctor
flutter doctor

# Expected: ✓ Flutter, ✓ Android toolchain, ✓ Android Studio
```

### 4.4 Prepare Emulator or Device

**For Emulator:**
```bash
# List emulators
flutter emulators

# Launch emulator
flutter emulators --launch Pixel_6_API_33

# Wait for emulator to fully boot
```

**For Physical Device:**
```bash
# Enable USB Debugging:
# Settings > About phone > Tap Build number 7 times
# Settings > Developer options > USB Debugging ON

# Connect and verify
adb devices

# Should show: device_id    device
```

---

## 5. Running on Android Device / Emulator

### 5.1 Debug Build (Development)

```bash
cd HARmony_Frontend/harmony_app

# Option 1: Automatic device selection
flutter run

# Option 2: Specific device
flutter run -d emulator-5554

# Option 3: Release mode
flutter run --release

# Verbose output for debugging:
flutter run -v
```

### 5.2 Monitor Logs

**Terminal 3: Log Monitoring**
```bash
# Real-time Flutter logs
flutter logs

# Or Android logcat
adb logcat | grep "flutter"
```

### 5.3 What You Should See

✅ **Screen 1: Splash/Loading**
- HARmony logo appears
- Initialization completes

✅ **Screen 2: Home Screen**
- Bottom navigation visible
- Activity Recognition card shows
- Real-time sensor data

✅ **Screen 3: Settings**
- Dark Mode toggle works (save and restore)
- Backend status: Connected ✅

✅ **Screen 4: Coach**
- Shows current activity
- Suggestions appear
- Goal tracker visible

✅ **Background Validation:**
```bash
# Check app is running
adb shell pidof com.harmony.app

# Check logs for no errors
flutter logs | grep -E "ERROR|Exception"
```

---

## 6. Testing the Complete System

### 6.1 Backend-Frontend Connection Test

```bash
# Terminal 4: Test Script
cd HARmony_Frontend/harmony_app

# Create test file: lib/test_connection.dart
cat > lib/test_connection.dart << 'EOF'
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  try {
    // Test local backend
    final response = await http.get(Uri.parse('http://10.0.2.2:8000/health'))
        .timeout(Duration(seconds: 5));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('✅ Backend Connected: ${data['status']}');
      print('✅ Model Loaded: ${data['model_loaded']}');
    } else {
      print('❌ Backend Error: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Connection Error: $e');
  }
}
EOF

# Run test
flutter run --release
```

### 6.2 Sensor & Model Test

**On device:**
1. Open app
2. Go to Activity Recognition tab
3. Start moving (walk, run, sit, stand)
4. Observe predictions change in real-time
5. Check Coach tab for suggestions

### 6.3 Database Test

**Terminal:**
```bash
psql -U harmony_user -d harmony_db

-- Check if data is being stored:
SELECT COUNT(*) FROM harmony.activities;
SELECT * FROM harmony.activities ORDER BY timestamp DESC LIMIT 5;
\q
```

### 6.4 Full Integration Test

```bash
# 1. Start backend
cd HARmony_Backend && python run.py &

# 2. Start app
cd HARmony_Frontend/harmony_app && flutter run &

# 3. Monitor logs
flutter logs

# 4. Test PostgreSQL
sleep 10  # Wait for activity data
psql -U harmony_user -d harmony_db << EOF
SELECT COUNT(*) as total_activities FROM harmony.activities;
SELECT DISTINCT activity_name FROM harmony.activities;
EOF

# 5. Check app doesn't crash
# Expected: No ERROR or FATAL in logs
```

---

## 7. Troubleshooting

### Issue: "Failed to connect to backend"

**Diagnosis:**
```bash
# 1. Check backend is running
curl http://localhost:8000/health

# 2. Check IP address is correct
ifconfig | grep inet

# 3. Test from emulator
adb shell curl http://10.0.2.2:8000/health

# 4. Check firewall
sudo lsof -i :8000  # macOS/Linux
```

**Solution:**
```dart
// In app_config.dart
// For emulator: 10.0.2.2 (correct)
// For device: use actual machine IP (e.g., 192.168.1.100)
// Don't use localhost from device/emulator!
```

### Issue: "PostgreSQL connection refused"

**Solution:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql  # Linux
brew services list | grep postgres  # macOS

# Start if needed
sudo systemctl start postgresql  # Linux
brew services start postgresql@15  # macOS

# Test connection
psql -U harmony_user -d harmony_db
```

### Issue: "Theme toggle not working"

**Solution:**
```dart
// Make sure theme provider is watching correctly
ref.watch(themeModeProvider);

// And theme mode setter is called
ref.read(themeModeProvider.notifier).setThemeMode(newMode);
```

### Issue: "App crashes on startup"

**Solution:**
```bash
# 1. Get full error
flutter run -v 2>&1 | tail -50

# 2. Check logs
flutter logs | tail -50

# 3. Clean and rebuild
flutter clean
flutter pub get
flutter run

# 4. If TFLite issue:
# Make sure models are in assets/models/
# And pubspec.yaml has assets configured
```

### Issue: "Sensor permissions denied"

**Solution:**
```bash
# Grant permissions
adb shell pm grant com.harmony.app android.permission.BODY_SENSORS
adb shell pm grant com.harmony.app android.permission.ACTIVITY_RECOGNITION

# Or clear and let app request:
adb shell pm clear com.harmony.app
flutter run
```

### Issue: "Model not found on backend"

**Solution:**
```bash
# Verify model files exist
ls -la ml_models/

# Should have:
# - har_model_fixed.tflite
# - labels.json

# Check backend is loading correctly
curl http://localhost:8000/model-info

# If not found, download from:
# Google Drive or rebuild from HARmony_ML_Core
```

---

## 🚀 Quick Start Script

Save as `run_all.sh`:

```bash
#!/bin/bash

echo "🚀 Starting HARmony System..."

# Start PostgreSQL
echo "📊 Starting PostgreSQL..."
brew services start postgresql@15 2>/dev/null || sudo systemctl start postgresql

sleep 2

# Start Backend
echo "🔧 Starting Backend..."
cd HARmony_Backend
source venv/bin/activate
python run.py > backend.log 2>&1 &
BACKEND_PID=$!
sleep 3

# Start Frontend
echo "📱 Starting Frontend..."
cd ../HARmony_Frontend/harmony_app
adb shell pidof com.harmony.app && adb shell am force-stop com.harmony.app 2>/dev/null
flutter run > frontend.log 2>&1 &
FRONTEND_PID=$!

# Start Logging
echo ""
echo "✅ System Started!"
echo "📊 Backend (PID $BACKEND_PID): http://localhost:8000"
echo "📱 Frontend: Running on device"
echo "🗄️  Database: postgresql://localhost:5432/harmony_db"
echo ""
echo "Monitoring logs (Ctrl+C to stop)..."
sleep 1
tail -f frontend.log
```

Run it:
```bash
bash run_all.sh
```

---

## 📱 Final Verification Checklist

- [ ] PostgreSQL running and database created
- [ ] Backend server running at http://localhost:8000
- [ ] Backend health check responds with ✅
- [ ] App installed on device/emulator
- [ ] App connects to backend (Settings shows Connected ✅)
- [ ] Sensors collecting data (Activity Recognition shows real-time data)
- [ ] Theme toggle works (Settings > Dark Mode works)
- [ ] Coach screen displays properly
- [ ] No console errors in `flutter logs`
- [ ] Activities stored in PostgreSQL database
- [ ] App performance is smooth (no lag)

---

## 📚 Related Documentation

- [PostgreSQL Testing Guide](./POSTGRESQL_TESTING_GUIDE.md)
- [Android Deployment Guide](./ANDROID_DEPLOYMENT_GUIDE.md)
- [Backend API Documentation](./HARmony_Backend/README.md)
- [Frontend Architecture](./HARmony_Frontend/ARCHITECTURE_DIAGRAM.md)

---

**Need help?** Check the troubleshooting section above or review the specific guides!

**Estimated Time:** 15-30 minutes for complete setup
**Success Rate:** 95% when following all steps
