import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:harmony_app/core/config/app_config.dart';

/// Manages the backend URL used by the app.  Stored in shared preferences so
/// it survives restarts and can be changed at runtime (e.g. when the host
/// machine moves to a different network).
class BackendConfigService extends ChangeNotifier {
  static const _prefsKey = 'backend_base_url';

  String _baseUrl = '';

  BackendConfigService() {
    _loadFromPrefs();
  }

  String get baseUrl => _baseUrl;

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefsKey) ?? '';
    if (_baseUrl.isEmpty) {
      // fallback to AppConfig default if nothing saved yet
      _baseUrl = AppConfig.apiBaseUrl;
    }
    // Force update to new localhost URL if still using old IP
    if (_baseUrl == 'http://192.168.8.106:8000' || _baseUrl == 'http://10.143.65.91:8000') {
      _baseUrl = AppConfig.apiBaseUrl;
      await prefs.setString(_prefsKey, _baseUrl);
    }
    notifyListeners();
  }

  Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, url);
    _baseUrl = url;
    notifyListeners();
  }
}
