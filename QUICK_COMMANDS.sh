#!/bin/bash
# 🚀 Quick Commands Reference for HARmony System

# ==================== DATABASE ====================
# Start PostgreSQL
brew services start postgresql@15        # macOS
sudo systemctl start postgresql           # Linux

# Setup database
cd HARmony_Backend && bash setup_postgres.sh

# Test database connection
psql -U harmony_user -d harmony_db
SELECT COUNT(*) FROM harmony.activities;

# ==================== BACKEND ====================
# Setup backend
cd HARmony_Backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Start backend
python run.py

# Test backend
curl http://localhost:8000/health

# ==================== FRONTEND ====================
# Setup frontend
cd HARmony_Frontend/harmony_app
flutter pub get

# Update configuration
nano lib/core/config/app_config.dart

# Start development
flutter run              # Debug
flutter run --release   # Release

# ==================== ANDROID ====================
# List devices/emulators
adb devices
flutter emulators

# Start emulator
flutter emulators --launch Pixel_6_API_33

# Install app
adb install build/app/outputs/apk/release/app-release.apk

# Monitor logs
flutter logs
adb logcat | grep flutter

# ==================== BUILD ====================
# Debug APK
flutter build apk

# Release APK (one file)
flutter build apk --release

# Release APKs (split by ABI - smaller size)
flutter build apk --release --split-per-abi

# App Bundle (for Google Play)
flutter build appbundle --release

# ==================== TESTING ====================
# Test connection
python3 << 'EOF'
import psycopg2
conn = psycopg2.connect("postgresql://harmony_user:harmony_password@localhost:5432/harmony_db")
print("✅ DB Connected")
conn.close()
EOF

# Check app health
curl http://localhost:8000/health | python -m json.tool

# Monitor performance
adb shell dumpsys meminfo com.harmony.app
adb shell top -p $(adb shell pidof com.harmony.app)

# ==================== CLEANUP ====================
# Stop backend
pkill -f "python run.py"

# Stop PostgreSQL
brew services stop postgresql@15         # macOS
sudo systemctl stop postgresql           # Linux

# Clear app data
adb shell pm clear com.harmony.app

# Uninstall app
adb uninstall com.harmony.app

# Clean build
flutter clean

# ==================== USEFUL SHORTCUTS ====================
# Get your local IP
ifconfig | grep "inet " | grep -v 127.0.0.1     # macOS
hostname -I                                       # Linux
ipconfig                                          # Windows

# Android Emulator can reach host via 10.0.2.2
# Physical device should use actual machine IP

# Create test data
psql -U harmony_user -d harmony_db << 'EOF'
INSERT INTO harmony.activities (user_id, activity_name, confidence) 
VALUES ('test', 'Walking', 0.95);
EOF

# View recent activities
psql -U harmony_user -d harmony_db -c \
  "SELECT * FROM harmony.activities ORDER BY timestamp DESC LIMIT 10;"

# ==================== PERFORMANCE TIPS ====================
# Reduce app size
flutter build apk --release --split-per-abi

# Enable code shrinking
# Edit android/app/build.gradle:
# minifyEnabled true
# shrinkResources true

# Monitor memory
watch -n 1 "adb shell dumpsys meminfo com.harmony.app | head -20"

# Profile app performance
flutter run --profile

# ==================== DEBUGGING ====================
# Get full crash log
flutter run -v 2>&1 | tail -100

# Check specific errors
flutter logs | grep ERROR

# Check database queries
psql -U harmony_user -d harmony_db
SELECT query, calls, total_time FROM pg_stat_statements ORDER BY total_time DESC;

# Kill port (if 8000 is in use)
lsof -i :8000 | tail -1 | awk '{print $2}' | xargs kill -9

# ==================== ONE-LINERS ====================
# Complete system start
brew services start postgresql@15 && cd HARmony_Backend && python run.py &  \
&& cd ../HARmony_Frontend/harmony_app && flutter run

# Full rebuild and run
flutter clean && flutter pub get && flutter run --release

# Build and install release APK
flutter build apk --release && adb install build/app/outputs/apk/release/app-release.apk

# Reset everything
flutter clean && adb shell pm clear com.harmony.app && flutter run
