import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class HealthDashboardScreen extends ConsumerStatefulWidget {
  const HealthDashboardScreen({super.key});

  @override
  ConsumerState<HealthDashboardScreen> createState() => _HealthDashboardScreenState();
}

class _HealthDashboardScreenState extends ConsumerState<HealthDashboardScreen> {
  bool _loading = true;
  int _activeMinutes = 0;
  int _inactiveMinutes = 0;
  int _dailyGoal = 45;
  int _steps = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    final storage = ref.read(activityStorageServiceProvider);
    final api = ref.read(apiServiceProvider);
    final settings = await storage.getSettings();
    _dailyGoal = (settings['dailyGoalMinutes'] as num?)?.toInt() ?? 45;

    final remote = await api.fetchRemoteSessions();
    final sessions = remote.isNotEmpty ? remote : await storage.getAllSessions();

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));

    int active = 0;
    int inactive = 0;

    for (final session in sessions) {
      if (session.endTime.isBefore(start) || session.startTime.isAfter(end)) continue;
      if (session.predictions.isNotEmpty) {
        active += estimateActiveMinutesFromPredictions(session.predictions);
        inactive += estimateInactiveMinutesFromPredictions(session.predictions);
      } else {
        active += session.duration.inMinutes;
      }
    }

    final steps = (active * 120).clamp(0, 20000).toInt();

    setState(() {
      _activeMinutes = active;
      _inactiveMinutes = inactive;
      _steps = steps;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);
    final score = _dailyGoal == 0 ? 0 : ((_activeMinutes / _dailyGoal) * 100).clamp(0, 100).round();
    final risk = _inactiveMinutes >= 120 || _activeMinutes < 20;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Health Dashboard'),
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
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildScoreCard(theme, score),
                  const SizedBox(height: 16),
                  if (risk) _buildRiskBanner(theme),
                  if (risk) const SizedBox(height: 16),
                  _buildActivityCard(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildScoreCard(ThemeProvider theme, int score) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: SfRadialGauge(
                axes: [
                  RadialAxis(
                    minimum: 0,
                    maximum: 100,
                    showLabels: false,
                    showTicks: false,
                    axisLineStyle: AxisLineStyle(
                      thickness: 0.2,
                      thicknessUnit: GaugeSizeUnit.factor,
                      color: theme.backgroundColor,
                    ),
                    pointers: [
                      RangePointer(
                        value: score.toDouble(),
                        width: 0.2,
                        sizeUnit: GaugeSizeUnit.factor,
                        color: TWColors.emerald500,
                        cornerStyle: CornerStyle.bothCurve,
                      )
                    ],
                    annotations: [
                      GaugeAnnotation(
                        widget: Text('$score', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 24)),
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daily Activity Score', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text('$_activeMinutes / $_dailyGoal min', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 6),
                  Text('Based on today\'s detected activity', style: TextStyle(color: theme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBanner(ThemeProvider theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TWColors.red500.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TWColors.red500.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: TWColors.red500),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Inactivity risk detected. Consider a short walk or stretching session.', style: TextStyle(color: theme.textPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today\'s Breakdown', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _metricRow(theme, 'Active Time', '${_activeMinutes} min'),
            _metricRow(theme, 'Inactive Time', '${_inactiveMinutes} min'),
            _metricRow(theme, 'Estimated Steps', '$_steps steps'),
            const SizedBox(height: 8),
            Text('Updated ${DateFormat('HH:mm').format(DateTime.now())}', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _metricRow(ThemeProvider theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: theme.textSecondary)),
          Text(value, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
