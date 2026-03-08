import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/features/activity_recognition/services/activity_storage_service.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:intl/intl.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final List<String> _motivationBank = const [
    'Small steps today create big wins tomorrow.',
    'Take a short walk — your body will thank you.',
    'Consistency beats intensity. Keep moving!',
    'Hydrate, stretch, and reset your posture.',
    'A two-minute break can lift your energy.'
  ];

  bool _loading = true;
  ActivityModel _current = ActivityModel(activity: 'Unknown', confidence: 0, timestamp: 0);
  DateTime _lastActiveAt = DateTime.now();
  String _smartSuggestion = 'Start a short movement burst to boost your day.';
  String _goalReminder = 'No goal set yet.';
  String? _remoteMotivation;
  int _dailyGoalMinutes = 45;
  int _activeMinutesToday = 0;
  List<Map<String, dynamic>> _alerts = [];
  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _inactivityTimer = Timer.periodic(const Duration(minutes: 1), (_) => _refreshSuggestion());
    // Set up listener in initState to avoid re-registering on every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupActivityListener();
    });
  }

  void _setupActivityListener() {
    ref.listen<ActivityModel>(
      currentActivityProvider,
      (previous, next) {
        _handleActivityUpdate(next);
      },
    );
  }

  @override
  void dispose() {
    _inactivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final storage = ref.read(activityStorageServiceProvider);
      final api = ref.read(apiServiceProvider);

      // Fetch settings and local data
      final settings = await storage.getSettings();
      final alerts = await storage.getCoachAlerts();
      final lastActive = settings['lastActiveAt'] as int?;
      final goal = (settings['dailyGoalMinutes'] as num?)?.toInt() ?? 45;

      // Calculate active minutes from local sessions
      final activeMinutes = await _calculateActiveMinutesToday(storage);

      // Try to fetch coach insights from backend
      String? remoteMotivation;
      try {
        final insights = await api.fetchCoachInsights();
        remoteMotivation = insights?['motivation']?.toString() ??
                           insights?['insight']?.toString() ??
                           insights?['message']?.toString();
      } catch (e) {
        if (kDebugMode) print('CoachScreen: Failed to fetch insights: $e');
      }

      if (mounted) {
        setState(() {
          _dailyGoalMinutes = goal;
          _activeMinutesToday = activeMinutes;
          _lastActiveAt = lastActive != null
              ? DateTime.fromMillisecondsSinceEpoch(lastActive)
              : DateTime.now().subtract(const Duration(minutes: 10));
          _alerts = alerts;
          _remoteMotivation = remoteMotivation ?? 'Connected to HARmony Coach';
          _loading = false;
        });
      }
      _refreshSuggestion();
      _refreshGoalReminder();
    } catch (e) {
      if (kDebugMode) print('CoachScreen bootstrap error: $e');
      if (mounted) {
        setState(() {
          _loading = false;
          _remoteMotivation = 'Coach unavailable - using offline mode';
        });
      }
    }
  }

  Future<int> _calculateActiveMinutesToday(ActivityStorageService storage) async {
    final sessions = await storage.getAllSessions();
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    int minutes = 0;
    for (final session in sessions) {
      if (session.endTime.isBefore(start) || session.startTime.isAfter(end)) continue;
      if (session.predictions.isNotEmpty) {
        minutes += estimateActiveMinutesFromPredictions(session.predictions);
      } else {
        minutes += session.duration.inMinutes;
      }
    }
    return minutes;
  }

  Future<void> _handleActivityUpdate(ActivityModel model) async {
    setState(() {
      _current = model;
    });

    final activity = normalizeActivityLabel(model.activity);
    if (isActiveActivity(activity)) {
      _lastActiveAt = DateTime.now();
      await ref.read(activityStorageServiceProvider).updateSettings({
        'lastActiveAt': _lastActiveAt.millisecondsSinceEpoch,
        'lastActivity': activity,
      });
      _refreshGoalReminder();
    }
    _refreshSuggestion();
  }

  void _refreshSuggestion() {
    final now = DateTime.now();
    final idleMinutes = now.difference(_lastActiveAt).inMinutes;
    String suggestion;
    if (idleMinutes >= 120) {
      suggestion = 'You have been inactive for 2+ hours. Stand, stretch, and walk for 5 minutes.';
    } else if (idleMinutes >= 60) {
      suggestion = 'It has been an hour of inactivity. Take a quick movement break.';
    } else if (normalizeActivityLabel(_current.activity) == 'Sitting') {
      suggestion = 'Sitting detected. Try a 2-minute stretch or short walk.';
    } else {
      suggestion = 'Keep the momentum. Aim for steady movement every hour.';
    }

    setState(() {
      _smartSuggestion = suggestion;
    });
  }

  void _refreshGoalReminder() {
    final remaining = (_dailyGoalMinutes - _activeMinutesToday).clamp(0, _dailyGoalMinutes);
    setState(() {
      _goalReminder = remaining == 0
          ? 'Goal achieved! Great job today.'
          : 'You are ${remaining} min away from your daily goal.';
    });
  }

  String _dailyMotivation() {
    if (_remoteMotivation != null && _remoteMotivation!.isNotEmpty) {
      return _remoteMotivation!;
    }
    final dayIndex = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return _motivationBank[dayIndex % _motivationBank.length];
  }

  Future<void> _logAlert(String type, String message) async {
    final storage = ref.read(activityStorageServiceProvider);
    final alert = {
      'type': type,
      'message': message,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'activity': normalizeActivityLabel(_current.activity),
    };
    await storage.addCoachAlert(alert);
    final alerts = await storage.getCoachAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);

    final activityLabel = normalizeActivityLabel(_current.activity);
    final confidence = (_current.confidence * 100).clamp(0, 100).toStringAsFixed(1);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('AI Coach'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _bootstrap(),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildStatusCard(theme, activityLabel, confidence),
                  const SizedBox(height: 16),
                  _buildSuggestionCard(theme),
                  const SizedBox(height: 16),
                  _buildMotivationCard(theme),
                  const SizedBox(height: 16),
                  _buildGoalCard(theme),
                  const SizedBox(height: 16),
                  _buildAlertsCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(ThemeProvider theme, String activityLabel, String confidence) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: activityColor(activityLabel).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.directions_walk, color: activityColor(activityLabel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Real-time Status', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(activityLabel, style: TextStyle(color: theme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TWColors.blue500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('$confidence% confidence', style: TextStyle(color: TWColors.blue500, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Last active: ${_timeFormat.format(_lastActiveAt)}', style: TextStyle(color: theme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: TWColors.emerald500),
                const SizedBox(width: 8),
                Text('Smart Suggestions', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_smartSuggestion, style: TextStyle(color: theme.textSecondary, height: 1.4)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _logAlert('move', 'Movement reminder sent'),
                  icon: const Icon(Icons.directions_walk, size: 18),
                  label: const Text('Log Move Alert'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _logAlert('hydrate', 'Hydration reminder sent'),
                  icon: const Icon(Icons.water_drop, size: 18),
                  label: const Text('Hydrate'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMotivationCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.favorite, color: TWColors.pink500),
                const SizedBox(width: 8),
                Text('Daily Motivation', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_dailyMotivation(), style: TextStyle(color: theme.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalCard(ThemeProvider theme) {
    final progress = _dailyGoalMinutes == 0 ? 0.0 : (_activeMinutesToday / _dailyGoalMinutes).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag, color: TWColors.blue500),
                const SizedBox(width: 8),
                Text('Goal Reminder', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text(_goalReminder, style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: theme.backgroundColor, color: TWColors.blue500),
            const SizedBox(height: 10),
            Text('$_activeMinutesToday / $_dailyGoalMinutes active minutes', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active, color: TWColors.amber500),
                    const SizedBox(width: 8),
                    Text('Alert History', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                TextButton(
                  onPressed: _alerts.isEmpty
                      ? null
                      : () async {
                          await ref.read(activityStorageServiceProvider).clearCoachAlerts();
                          final alerts = await ref.read(activityStorageServiceProvider).getCoachAlerts();
                          if (mounted) setState(() => _alerts = alerts);
                        },
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_alerts.isEmpty)
              Text('No alerts yet. Coach actions will appear here.', style: TextStyle(color: theme.textSecondary))
            else
              ..._alerts.take(5).map((alert) {
                final ts = DateTime.fromMillisecondsSinceEpoch(alert['timestamp'] as int? ?? 0);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: TWColors.amber500.withOpacity(0.15),
                    child: Icon(Icons.notification_important, color: TWColors.amber500, size: 18),
                  ),
                  title: Text(alert['message']?.toString() ?? 'Alert', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: Text('${alert['activity'] ?? 'Activity'} • ${_timeFormat.format(ts)}', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
