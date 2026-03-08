import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';
import 'package:harmony_app/shared/utils/activity_utils.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';

class AcademicScreen extends ConsumerStatefulWidget {
  const AcademicScreen({super.key});

  @override
  ConsumerState<AcademicScreen> createState() => _AcademicScreenState();
}

class _AcademicScreenState extends ConsumerState<AcademicScreen> {
  Map<String, dynamic>? _modelConfig;
  Map<String, dynamic>? _modelInsights;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _loadInsights();
  }

  Future<void> _loadConfig() async {
    try {
      final raw = await rootBundle.loadString('assets/config/model_config.json');
      setState(() {
        _modelConfig = jsonDecode(raw) as Map<String, dynamic>;
        _loadingConfig = false;
      });
    } catch (_) {
      setState(() {
        _modelConfig = null;
        _loadingConfig = false;
      });
    }
  }

  Future<void> _loadInsights() async {
    final api = ref.read(apiServiceProvider);
    final insights = await api.fetchModelInsights();
    if (mounted) {
      setState(() => _modelInsights = insights);
    }
  }

  Map<String, double> _computeStats(List<double> values) {
    if (values.isEmpty) return {'mean': 0, 'std': 0, 'var': 0};
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    final std = sqrt(variance);
    return {'mean': mean, 'std': std, 'var': variance};
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);
    final activity = ref.watch(currentActivityProvider);
    final sensorService = ref.watch(sensorServiceProvider);

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Academic / XAI'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildModelCard(theme, activity),
          const SizedBox(height: 16),
          _buildConfigCard(theme),
          const SizedBox(height: 16),
          StreamBuilder<SensorWindow>(
            stream: sensorService.sensorWindowStream,
            builder: (context, snapshot) {
              final window = snapshot.data;
              if (window == null) {
                return _buildNoDataCard(theme);
              }
              final accMagnitudes = window.accelerometer.map((a) => sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])).toList();
              final gyroMagnitudes = window.gyroscope.map((g) => sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2])).toList();
              final accStats = _computeStats(accMagnitudes);
              final gyroStats = _computeStats(gyroMagnitudes);
              return _buildFeatureCard(theme, accStats, gyroStats);
            },
          ),
          const SizedBox(height: 16),
          _buildExplanationCard(theme, activity),
          const SizedBox(height: 16),
          _buildFutureNotesCard(theme),
        ],
      ),
    );
  }

  Widget _buildModelCard(ThemeProvider theme, ActivityModel activity) {
    final label = normalizeActivityLabel(activity.activity);
    final confidence = (activity.confidence * 100).clamp(0, 100).toStringAsFixed(1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Confidence', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: activityColor(label).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.psychology, color: activityColor(label)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(color: theme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                    Text('$confidence% confidence', style: TextStyle(color: theme.textSecondary)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard(ThemeProvider theme) {
    if (_loadingConfig) {
      return const Center(child: CircularProgressIndicator());
    }
    final config = _modelConfig;
    final accuracy = _modelInsights?['accuracy']?.toString() ?? '89% (baseline)';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Model Details', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _buildKeyValue(theme, 'Version', config?['model_version']?.toString() ?? 'Unknown'),
            _buildKeyValue(theme, 'Window Size', config?['window_size']?.toString() ?? 'N/A'),
            _buildKeyValue(theme, 'Sampling Rate', '${config?['sampling_rate'] ?? 'N/A'} Hz'),
            _buildKeyValue(theme, 'Feature Count', config?['feature_count']?.toString() ?? 'N/A'),
            _buildKeyValue(theme, 'Validation Accuracy', accuracy)
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors_off, color: TWColors.slate500),
                const SizedBox(width: 8),
                Text('Extracted Features', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            Text('Start monitoring in the Realtime screen to view live feature statistics.', style: TextStyle(color: theme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(ThemeProvider theme, Map<String, double> acc, Map<String, double> gyro) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Extracted Features', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('Accelerometer (m/s²)', style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 6),
            _buildStatRow(theme, acc),
            const SizedBox(height: 12),
            Text('Gyroscope (rad/s)', style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 6),
            _buildStatRow(theme, gyro),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(ThemeProvider theme, Map<String, double> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetric(theme, 'Mean', stats['mean'] ?? 0),
        _buildMetric(theme, 'Std', stats['std'] ?? 0),
        _buildMetric(theme, 'Var', stats['var'] ?? 0),
      ],
    );
  }

  Widget _buildMetric(ThemeProvider theme, String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: theme.textSecondary, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value.toStringAsFixed(3), style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildExplanationCard(ThemeProvider theme, ActivityModel activity) {
    final label = normalizeActivityLabel(activity.activity);
    final remoteExplanation = _modelInsights?['explanation']?.toString();
    final explanation = remoteExplanation?.isNotEmpty == true
        ? remoteExplanation!
        : label == 'Walking'
        ? 'Steady accelerometer variance and rhythmic gyroscope patterns indicate a walking gait.'
        : label == 'Running'
            ? 'Higher magnitude and faster oscillations suggest running cadence.'
            : label == 'Sitting'
                ? 'Low variance with minimal movement across sensors indicates sitting.'
                : 'Model is collecting signals to refine this prediction.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prediction Explanation', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(explanation, style: TextStyle(color: theme.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureNotesCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Future Improvements', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text('• Add gyroscope fusion for richer motion patterns\n• Increase model robustness with diverse datasets\n• Explain predictions with SHAP-style contributions', style: TextStyle(color: theme.textSecondary, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildKeyValue(ThemeProvider theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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
