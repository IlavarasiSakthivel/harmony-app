import 'dart:io';
import 'dart:math';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class DataHistoryScreen extends ConsumerStatefulWidget {
  const DataHistoryScreen({super.key});

  @override
  ConsumerState<DataHistoryScreen> createState() => _DataHistoryScreenState();
}

class _DataHistoryScreenState extends ConsumerState<DataHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  bool _loading = true;
  List<ActivitySession> _sessions = [];
  List<Map<String, dynamic>> _snapshots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final storage = ref.read(activityStorageServiceProvider);
    final api = ref.read(apiServiceProvider);

    final remote = await api.fetchRemoteSessions();
    _sessions = remote.isNotEmpty ? remote : await storage.getAllSessions();
    _snapshots = await storage.getSensorSnapshots();

    setState(() => _loading = false);
  }

  Future<void> _captureSnapshot() async {
    final sensorService = ref.read(sensorServiceProvider);
    final storage = ref.read(activityStorageServiceProvider);
    final startedHere = !sensorService.isRunning;
    if (startedHere) sensorService.startSensors();

    await Future.delayed(const Duration(milliseconds: 1200));

    final acc = sensorService.accelerometerEvents.take(30).map((e) => [e.x, e.y, e.z]).toList();
    final gyro = sensorService.gyroscopeEvents.take(30).map((e) => [e.x, e.y, e.z]).toList();

    if (startedHere) sensorService.stopSensors();

    if (acc.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No sensor data available yet. Start monitoring first.')),
        );
      }
      return;
    }

    final accMagnitudes = acc.map((v) => sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])).toList();
    final gyroMagnitudes = gyro.map((v) => sqrt(v[0] * v[0] + v[1] * v[1] + v[2] * v[2])).toList();

    double mean(List<double> v) => v.reduce((a, b) => a + b) / v.length;
    double variance(List<double> v) {
      final m = mean(v);
      return v.map((x) => (x - m) * (x - m)).reduce((a, b) => a + b) / v.length;
    }

    final snapshot = {
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'accelerometer': acc,
      'gyroscope': gyro,
      'features': {
        'acc_mean': mean(accMagnitudes),
        'acc_var': variance(accMagnitudes),
        'gyro_mean': mean(gyroMagnitudes),
        'gyro_var': variance(gyroMagnitudes),
      }
    };

    await storage.addSensorSnapshot(snapshot);
    _snapshots = await storage.getSensorSnapshots();
    if (mounted) setState(() {});
  }

  Future<void> _exportSnapshotsCsv() async {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Acc Mean,Acc Var,Gyro Mean,Gyro Var');
    for (final snap in _snapshots) {
      final features = Map<String, dynamic>.from(snap['features'] as Map? ?? {});
      buffer.writeln('${snap['timestamp']},${features['acc_mean'] ?? 0},${features['acc_var'] ?? 0},${features['gyro_mean'] ?? 0},${features['gyro_var'] ?? 0}');
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/harmony_sensor_snapshots.csv');
    await file.writeAsString(buffer.toString());
    await Share.shareXFiles([XFile(file.path)], text: 'HARmony sensor snapshots');
  }

  Future<void> _exportSessionsCsv() async {
    final csv = await ref.read(activityStorageServiceProvider).exportSessionsAsCsv();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/harmony_sessions.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)], text: 'HARmony session history');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.backgroundColor,
        appBar: AppBar(
          title: const Text('Data History'),
          backgroundColor: theme.cardColor,
          foregroundColor: theme.textPrimary,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: const TabBar(tabs: [
            Tab(text: 'Sessions'),
            Tab(text: 'Sensor Logs'),
          ]),
          actions: [
            IconButton(icon: const Icon(Icons.download), onPressed: _exportSessionsCsv),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildSessionsTab(theme),
                  _buildSnapshotsTab(theme),
                ],
              ),
      ),
    );
  }

  Widget _buildSessionsTab(ThemeProvider theme) {
    if (_sessions.isEmpty) {
      return Center(child: Text('No sessions recorded yet.', style: TextStyle(color: theme.textSecondary)));
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _sessions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final summary = normalizeActivityLabel(session.summary ?? 'Mixed');
          return Card(
            child: ExpansionTile(
              title: Text(summary, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text('${_dateFormat.format(session.startTime)} • ${session.duration.inMinutes} min', style: TextStyle(color: theme.textSecondary)),
              children: [
                if (session.predictions.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No prediction details stored for this session.', style: TextStyle(color: theme.textSecondary)),
                  )
                else
                  ...session.predictions.map((p) => ListTile(
                        dense: true,
                        leading: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(color: activityColor(p.activity), shape: BoxShape.circle),
                        ),
                        title: Text(normalizeActivityLabel(p.activity), style: TextStyle(color: theme.textPrimary)),
                        subtitle: Text(_dateFormat.format(p.timestamp), style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                        trailing: Text('${(p.confidence * 100).toStringAsFixed(0)}%', style: TextStyle(color: theme.textSecondary)),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSnapshotsTab(ThemeProvider theme) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sensor Snapshot', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Capture a short burst of raw sensor values and feature stats.', style: TextStyle(color: theme.textSecondary)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _captureSnapshot,
                        icon: const Icon(Icons.sensors),
                        label: const Text('Capture'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _snapshots.isEmpty ? null : _exportSnapshotsCsv,
                        icon: const Icon(Icons.download),
                        label: const Text('Export CSV'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_snapshots.isEmpty)
            Text('No snapshots recorded yet.', style: TextStyle(color: theme.textSecondary))
          else
            ..._snapshots.map((snap) {
              final ts = DateTime.fromMillisecondsSinceEpoch(snap['timestamp'] as int? ?? 0);
              final features = Map<String, dynamic>.from(snap['features'] as Map? ?? {});
              final acc = (snap['accelerometer'] as List).take(3).toList();
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_dateFormat.format(ts), style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Acc mean: ${features['acc_mean']?.toStringAsFixed(3) ?? '0'} | Acc var: ${features['acc_var']?.toStringAsFixed(3) ?? '0'}', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                      Text('Gyro mean: ${features['gyro_mean']?.toStringAsFixed(3) ?? '0'} | Gyro var: ${features['gyro_var']?.toStringAsFixed(3) ?? '0'}', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                      const SizedBox(height: 8),
                      Text('Raw accel (sample): $acc', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
