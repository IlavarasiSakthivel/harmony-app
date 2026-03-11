import 'dart:io';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  final DateFormat _dayFormat = DateFormat('MMM d');
  bool _loading = true;
  String _range = 'weekly';
  List<ActivitySession> _sessions = [];

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() => _loading = true);
    final storage = ref.read(activityStorageServiceProvider);
    final api = ref.read(apiServiceProvider);

    final remote = await api.fetchRemoteSessions();
    if (remote.isNotEmpty) {
      _sessions = remote;
    } else {
      _sessions = await storage.getAllSessions();
    }

    setState(() => _loading = false);
  }

  List<DateTime> _rangeDates() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int days;
    if (_range == 'daily') {
      days = 1;
    } else if (_range == 'monthly') {
      days = 30;
    } else {
      days = 7;
    }
    return List.generate(days, (i) => today.subtract(Duration(days: days - 1 - i)));
  }

  Map<String, List<ActivityPrediction>> _predictionsByDay() {
    final map = <String, List<ActivityPrediction>>{};
    for (final session in _sessions) {
      for (final pred in session.predictions) {
        final key = DateFormat('yyyy-MM-dd').format(pred.timestamp);
        map.putIfAbsent(key, () => []).add(pred);
      }
    }
    return map;
  }

  List<double> _activeMinutesByDay() {
    final dates = _rangeDates();
    final predsByDay = _predictionsByDay();
    return dates.map((d) {
      final key = DateFormat('yyyy-MM-dd').format(d);
      final preds = predsByDay[key] ?? [];
      if (preds.isNotEmpty) {
        return estimateActiveMinutesFromPredictions(preds).toDouble();
      }
      final sessionsForDay = _sessions.where((s) => s.startTime.year == d.year && s.startTime.month == d.month && s.startTime.day == d.day);
      return sessionsForDay.fold<double>(0.0, (sum, s) => sum + s.duration.inMinutes.toDouble());
    }).toList();
  }

  Map<String, int> _activityDistributionForRange() {
    final dates = _rangeDates();
    final start = dates.first;
    final end = dates.last.add(const Duration(days: 1));
    final preds = flattenPredictions(_sessions).where((p) => p.timestamp.isAfter(start) && p.timestamp.isBefore(end)).toList();
    if (preds.isEmpty) {
      return {'No data': 1};
    }
    return activityDistribution(preds);
  }

  double _currentTotal() {
    return _activeMinutesByDay().fold(0.0, (a, b) => a + b);
  }

  double _previousTotal() {
    final dates = _rangeDates();
    final length = dates.length;
    final start = dates.first.subtract(Duration(days: length));
    final end = dates.first;
    final preds = flattenPredictions(_sessions).where((p) => p.timestamp.isAfter(start) && p.timestamp.isBefore(end)).toList();
    if (preds.isNotEmpty) {
      return estimateActiveMinutesFromPredictions(preds).toDouble();
    }
    return 0.0;
  }

  /// Calculate daily activity score from 0-100 based on activity minutes and consistency
  int _calculateDailyScore() {
    final today = DateTime.now();
    final todayKey = DateFormat('yyyy-MM-dd').format(today);
    
    // Get predictions for today
    final todayPredictions = flattenPredictions(_sessions)
        .where((p) => DateFormat('yyyy-MM-dd').format(p.timestamp) == todayKey)
        .toList();
    
    if (todayPredictions.isEmpty) return 0;
    
    // Calculate metrics
    int score = 0;
    
    // 1. Activity duration (max 40 points for ~60 minutes)
    final activeMinutes = estimateActiveMinutesFromPredictions(todayPredictions);
    score += (activeMinutes / 60 * 40).clamp(0, 40).toInt();
    
    // 2. Activity variety (max 30 points)
    final activities = <String>{};
    for (final pred in todayPredictions) {
      if (!['Sitting', 'Standing', 'Laying'].contains(pred.activity)) {
        activities.add(pred.activity);
      }
    }
    score += (activities.length * 10).clamp(0, 30);
    
    // 3. Consistency (max 20 points - if session started and completed)
    final hasMorningSessions = todayPredictions.any((p) => p.timestamp.hour < 12);
    final hasEveningSessions = todayPredictions.any((p) => p.timestamp.hour >= 12);
    if (hasMorningSessions && hasEveningSessions) score += 20;
    
    // 4. Average confidence (max 10 points)
    if (todayPredictions.isNotEmpty) {
      final avgConfidence = todayPredictions.fold(0.0, (sum, p) => sum + p.confidence) / todayPredictions.length;
      score += (avgConfidence * 10).toInt();
    }
    
    return score.clamp(0, 100);
  }

  Future<void> _exportSummary() async {
    final dates = _rangeDates();
    final activeByDay = _activeMinutesByDay();
    final buffer = StringBuffer();
    buffer.writeln('Date,Active Minutes');
    for (int i = 0; i < dates.length; i++) {
      buffer.writeln('${DateFormat('yyyy-MM-dd').format(dates[i])},${activeByDay[i].toStringAsFixed(1)}');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/harmony_analytics_${_range}.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'HARmony analytics summary ($_range)');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);
    final activeByDay = _activeMinutesByDay();
    final dates = _rangeDates();
    final distribution = _activityDistributionForRange();
    final total = _currentTotal();
    final previous = _previousTotal();
    final delta = total - previous;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportSummary,
            tooltip: 'Export summary',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSessions,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildRangeSelector(theme),
                  const SizedBox(height: 16),
                  _buildSummaryCards(theme, total, delta),
                  const SizedBox(height: 16),
                  _buildBarChart(theme, dates, activeByDay),
                  const SizedBox(height: 16),
                  _buildLineChart(theme, dates, activeByDay),
                  const SizedBox(height: 16),
                  _buildPieChart(theme, distribution),
                ],
              ),
            ),
    );
  }

  Widget _buildRangeSelector(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _rangeChip(theme, 'daily', 'Daily'),
            _rangeChip(theme, 'weekly', 'Weekly'),
            _rangeChip(theme, 'monthly', 'Monthly'),
          ],
        ),
      ),
    );
  }

  Widget _rangeChip(ThemeProvider theme, String value, String label) {
    final selected = _range == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: TWColors.blue500,
      labelStyle: TextStyle(color: selected ? Colors.white : theme.textPrimary),
      onSelected: (_) {
        setState(() => _range = value);
      },
    );
  }

  Widget _buildSummaryCards(ThemeProvider theme, double total, double delta) {
    final deltaColor = delta >= 0 ? TWColors.emerald500 : TWColors.red500;
    final deltaLabel = delta >= 0 ? 'up' : 'down';
    final dailyScore = _calculateDailyScore();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Score', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('$dailyScore/100', style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: dailyScore / 100,
                      backgroundColor: theme.isDarkMode ? TWColors.slate700 : TWColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(_getScoreColor(dailyScore)),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Active Minutes', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text(total.toStringAsFixed(1), style: TextStyle(color: theme.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 200,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Trend vs Previous', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('${delta.abs().toStringAsFixed(1)} min $deltaLabel', style: TextStyle(color: deltaColor, fontSize: 18, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on activity score
  Color _getScoreColor(int score) {
    if (score >= 80) return TWColors.emerald500;
    if (score >= 60) return TWColors.amber500;
    if (score >= 40) return TWColors.orange500;
    return TWColors.red500;
  }

  Widget _buildBarChart(ThemeProvider theme, List<DateTime> dates, List<double> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Volume', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 20)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _dayFormat.format(dates[index]),
                              style: TextStyle(color: theme.textSecondary, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(values.length, (index) {
                    return BarChartGroupData(x: index, barRods: [
                      BarChartRodData(toY: values[index], width: 14, color: TWColors.blue500, borderRadius: BorderRadius.circular(6)),
                    ]);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(ThemeProvider theme, List<DateTime> dates, List<double> values) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Movement Intensity', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= dates.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _dayFormat.format(dates[index]),
                              style: TextStyle(color: theme.textSecondary, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i])),
                      isCurved: true,
                      color: TWColors.emerald500,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(ThemeProvider theme, Map<String, int> distribution) {
    final total = distribution.values.fold<int>(0, (a, b) => a + b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activity Distribution', style: TextStyle(color: theme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sections: distribution.entries.map((entry) {
                          final value = entry.value.toDouble();
                          return PieChartSectionData(
                            value: value,
                            color: activityColor(entry.key),
                            title: total == 0 ? '' : '${(value / total * 100).toStringAsFixed(0)}%',
                            radius: 60,
                            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: distribution.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(width: 10, height: 10, decoration: BoxDecoration(color: activityColor(entry.key), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text('${entry.key} (${entry.value})', style: TextStyle(color: theme.textSecondary))),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
