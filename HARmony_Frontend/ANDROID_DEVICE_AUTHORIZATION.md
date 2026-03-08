# 📱 Android Device Authorization Guide
Your device is **detected but unauthorized**. This is a security feature - you need to authorize USB debugging on your phone.
## ✅ Step-by-Step Fix
### Step 1: Check Current Status
```bash
adb devices
```
You'll see something like:
```
List of attached devices
10AE1M17C2001RX           unauthorized
```
### Step 2: Look at Your Phone
**Check your Android device screen** for a dialog that says:
```
"Allow USB Debugging?"
```
### Step 3: Authorize on Phone
1. **Read the dialog carefully** - it shows your computer's fingerprint
2. **Check the box**: "Always allow from this computer"  
3. **Tap**: "Allow" or "OK"
### Step 4: Verify Authorization
```bash
adb devices
```
Should now show:
```
List of attached devices
10AE1M17C2001RX           device
```
### Step 5: Run Flutter App
```bash
cd ~/Documents/Final_Project/HARmony_Frontend/harmony_app
flutter run -d 10AE1M17C2001RX
```
---
## 🔧 If Dialog Doesn't Appear
### Option 1: Reconnect Device
```bash
# Disconnect USB cable completely (wait 5 seconds)
# Plug it back in
adb devices  # Check again
```
### Option 2: Toggle USB Debugging
1. Go to **Settings** → **Developer Options**
2. Turn **USB Debugging** OFF
3. Turn **USB Debugging** ON again
4. Reconnect via USB
### Option 3: Revoke All Authorizations
```bash
# On phone: Settings → Developer Options
# Tap: "Revoke USB Debugging Authorizations"
# Reconnect USB cable
# Check for authorization dialog
```
### Option 4: Check USB Mode
1. Open **Settings** on your phone
2. Go to **About Phone**
3. Find "USB Connection Mode" or similar
4. Change from "Charge Only" to **"File Transfer"** or **"PTP"**
5. Reconnect
---
## 💡 Pro Tips
- **Always check** your phone screen after plugging in USB
- **Authorization persists** - you only do this once per computer
- **Multiple devices?** Each device needs separate authorization
- **Still not working?** Try a different USB cable (some cables don't support data transfer)
---
## ✅ Once Authorized
Run the app:
```bash
cd ~/Documents/Final_Project/HARmony_Frontend/harmony_app
flutter run -d 10AE1M17C2001RX
```
Or just:
```bash
flutter run
```
Flutter will auto-select the authorized device!
---
## 🐛 Debug Commands
```bash
# Force ADB server restart
adb kill-server
adb start-server
adb devices
# Clear ADB cache
adb shell pm clear com.android.settings
# Show ADB connection details
adb devices -l
```
---
**Device ID: 10AE1M17C2001RX**  
**Status:** Waiting for authorization on phone
