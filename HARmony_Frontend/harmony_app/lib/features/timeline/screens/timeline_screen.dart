import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:intl/intl.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
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
    _sessions = remote.isNotEmpty ? remote : await storage.getAllSessions();

    setState(() => _loading = false);
  }

  List<ActivityPrediction> _predictionsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return _sessions
        .expand((s) => s.predictions)
        .where((p) => p.timestamp.isAfter(start) && p.timestamp.isBefore(end))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Map<String, int> _summaryForDate(List<ActivityPrediction> predictions) {
    final dist = activityDistribution(predictions);
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);
    final predictions = _predictionsForDate(_selectedDate);
    final summary = _summaryForDate(predictions);
    final topActivity = summary.entries.isEmpty
        ? 'No data'
        : summary.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Activity Timeline'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 30)),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
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
                  _buildSummaryCard(theme, predictions.length, topActivity),
                  const SizedBox(height: 16),
                  _buildTimelineList(theme, predictions),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(ThemeProvider theme, int count, String topActivity) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary • ${_dateFormat.format(_selectedDate)}', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryItem(theme, 'Events', count.toString()),
                _summaryItem(theme, 'Top Activity', topActivity),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(ThemeProvider theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildTimelineList(ThemeProvider theme, List<ActivityPrediction> predictions) {
    if (predictions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text('No predictions recorded for this date.', style: TextStyle(color: theme.textSecondary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(predictions.length, (index) {
        final current = predictions[index];
        final next = index + 1 < predictions.length ? predictions[index + 1] : null;
        final duration = next != null
            ? next.timestamp.difference(current.timestamp)
            : Duration(seconds: predictionWindowSeconds.toInt());
        final label = normalizeActivityLabel(current.activity);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: ListTile(
              leading: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: activityColor(label), shape: BoxShape.circle),
              ),
              title: Text(label, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('${_timeFormat.format(current.timestamp)} • ${duration.inMinutes} min', style: TextStyle(color: theme.textSecondary)),
              trailing: Text('${(current.confidence * 100).toStringAsFixed(0)}%', style: TextStyle(color: theme.textSecondary)),
            ),
          ),
        );
      }),
    );
  }
}
