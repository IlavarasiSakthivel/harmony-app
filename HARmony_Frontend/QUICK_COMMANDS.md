# ⚡ HARmony - Quick Commands
## 🚀 Start Everything
**Terminal 1 - Flask Backend:**
```bash
cd ~/backend
python app.py
# Should show: * Running on http://127.0.0.1:5000
```
**Terminal 2 - Flutter App:**
```bash
cd ~/Documents/Final_Project/HARmony_Frontend/harmony_app
# For Emulator:
flutter run
# For Physical Device:
flutter run -d $(flutter devices -d | head -1)
# For Release:
flutter run --release
```
## 🔧 Essential Commands
```bash
# Build & run
flutter clean && flutter pub get && flutter run
# Release APK
flutter build apk --release
# Check devices
flutter devices
# Logs
flutter logs
# Build runner
flutter pub run build_runner build
```
## 🗄️ PostgreSQL
```bash
# Start database
sudo systemctl start postgresql  # Linux
brew services start postgresql  # Mac
# Connect
psql -U postgres -d harmony_db
# Check tables
\dt
```
## 🔌 Network
**Find your IP:**
```bash
ifconfig | grep "inet " | grep -v 127.0.0.1  # Mac/Linux
ipconfig  # Windows
```
**Update app URL in `app_providers.dart` line 32:**
- Emulator: `http://10.0.2.2:5000`
- Device: `http://192.168.x.x:5000`
- Desktop: `http://localhost:5000`
## ✅ Full Setup Checklist
- [ ] Flask running on 5000
- [ ] PostgreSQL running
- [ ] Device/emulator connected
- [ ] Base URL configured
- [ ] `flutter pub get` done
- [ ] App runs without errors
