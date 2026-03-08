import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications for smart alerts (e.g. inactivity after 40 min sitting).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    if (Platform.isAndroid) {
      await _requestAndroidPermissions();
    }
    _initialized = true;
    if (kDebugMode) debugPrint('[NotificationService] Initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) debugPrint('[NotificationService] Tapped: ${response.payload}');
  }

  Future<void> _requestAndroidPermissions() async {
    // Optional: request exact alarm / post notifications for Android 13+
    // final impl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    // if (impl != null) { await impl.requestNotificationsPermission(); }
  }

  /// Show an inactivity reminder (e.g. "You've been sitting for 40 min. Try to walk now.").
  Future<void> showInactivityReminder({String? body}) async {
    if (!_initialized) await initialize();
    const android = AndroidNotificationDetails(
      'harmony_inactivity',
      'Inactivity Alerts',
      channelDescription: 'Reminders when sedentary for too long',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    const details = NotificationDetails(android: android, iOS: ios);
    await _plugin.show(
      1,
      'Time to move',
      body ?? "You've been sitting for a while. Try to walk now.",
      details,
    );
  }

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
