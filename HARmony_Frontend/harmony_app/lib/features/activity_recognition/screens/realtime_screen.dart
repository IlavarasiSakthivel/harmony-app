import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, ThemeProvider;
import 'package:fl_chart/fl_chart.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:harmony_app/core/services/backend_config_service.dart';
import 'package:harmony_app/features/activity_recognition/widgets/sensor_buffering_progress_widget.dart';
import 'package:harmony_app/features/activity_recognition/widgets/connection_status_indicator.dart';

class RealtimeRecognitionScreen extends ConsumerStatefulWidget {
  const RealtimeRecognitionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<RealtimeRecognitionScreen> createState() => _RealtimeRecognitionScreenState();
}

class _RealtimeRecognitionScreenState extends ConsumerState<RealtimeRecognitionScreen> {
  // Settings
  bool _saveHistory = true;

  // State variables
  String _currentActivity = 'Unknown';
  double _confidence = 0.0;
  bool _isMonitoring = false;
  int _stepCount = 0;
  int _totalPredictions = 0;
  DateTime? _sessionStartTime;
  final List<Map<String, dynamic>> _predictionHistory = [];
  String _statusMessage = 'Initializing...';
  bool _isCollectingData = false;
  String _modelStatus = 'loading'; // loading | loaded | error
  String? _modelError;

  // Backend status tracking
  bool _backendHealthy = false;
  bool _modelLoaded = false;
  String _backendError = '';
  Map<String, double>? _lastPredictionProbabilities;

  // Chart data - using growable lists for accelerometer events
  final List<double> _accelerometerX = List.generate(50, (index) => 0.0);
  final List<double> _accelerometerY = List.generate(50, (index) => 0.0);
  final List<double> _accelerometerZ = List.generate(50, (index) => 0.0);

  double _minAccelerometer = -3.0; // Dynamic min for chart
  double _maxAccelerometer = 3.0; // Dynamic max for chart

  StreamSubscription? _accelerometerStreamSubscription;
  StreamSubscription? _gyroscopeStreamSubscription;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _statusMessage = '✓ Ready to start monitoring';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendConnection();
    });
  }

  Future<void> _checkBackendConnection() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final isConnected = await apiService.checkConnection();
      if (mounted) {
        setState(() {
          if (isConnected) {
            _statusMessage = '✓ Connected to Flask backend';
            _modelStatus = 'loaded';
            _backendError = '';
            _backendHealthy = true;
            _modelLoaded = true;
          } else {
            _statusMessage = '⚠ Flask backend unavailable - using local mode';
            _modelStatus = 'error';
            _backendError = 'Unable to reach backend';
            _backendHealthy = false;
            _modelLoaded = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = '⚠ Connection error: $e';
          _modelStatus = 'error';
          _backendHealthy = false;
          _modelLoaded = false;
        });
      }
    }
  }

  Future<void> _checkBackendStatus() async {
    _checkBackendConnection();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await ref.read(activityStorageServiceProvider).getSettings();
      if (mounted) {
        setState(() {
          _saveHistory = settings['saveHistory'] as bool? ?? true;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _saveHistory = true; });
    }
  }

  // utility for showing transient messages to the user
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _startMonitoring() async {
    if (_isMonitoring) return;

    // Check backend availability before beginning data collection
    final api = ref.read(apiServiceProvider);
    final connected = await api.checkConnection();
    if (!connected) {
      if (mounted) {
        setState(() {
          _backendError = 'Unable to reach backend';
          _modelStatus = 'error';
          _statusMessage = '⚠ Backend unreachable - cannot start';
        });
      }
      _showSnackBar('Cannot start monitoring: backend unreachable', TWColors.red500);
      return;
    }

    final sensorService = ref.read(sensorServiceProvider);

    setState(() {
      _isMonitoring = true;
      _sessionStartTime = DateTime.now();
      _statusMessage = '📍 Monitoring started - Collecting sensor data...';
      _isCollectingData = true;
      _backendError = '';
    });

    sensorService.startSensors();

    // Listen to individual accelerometer events
    _accelerometerStreamSubscription = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      if (mounted) {
        setState(() {
          _accelerometerX.removeAt(0);
          _accelerometerY.removeAt(0);
          _accelerometerZ.removeAt(0);
          _accelerometerX.add(event.x);
          _accelerometerY.add(event.y);
          _accelerometerZ.add(event.z);

          _minAccelerometer = [
            _accelerometerX.reduce((a, b) => a < b ? a : b),
            _accelerometerY.reduce((a, b) => a < b ? a : b),
            _accelerometerZ.reduce((a, b) => a < b ? a : b),
          ].reduce((a, b) => a < b ? a : b) - 0.5;

          _maxAccelerometer = [
            _accelerometerX.reduce((a, b) => a > b ? a : b),
            _accelerometerY.reduce((a, b) => a > b ? a : b),
            _accelerometerZ.reduce((a, b) => a > b ? a : b),
          ].reduce((a, b) => a > b ? a : b) + 0.5;
        });
      }
    });

    _gyroscopeStreamSubscription = gyroscopeEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((event) {
      // Gyroscope collection for potential future use
    });
  }

  void _stopMonitoring() async {
    final sensorService = ref.read(sensorServiceProvider);
    sensorService.stopSensors();
    _accelerometerStreamSubscription?.cancel();
    _accelerometerStreamSubscription = null;
    _gyroscopeStreamSubscription?.cancel();
    _gyroscopeStreamSubscription = null;

    // Save session to both local database and remote backend if enabled
    if (_saveHistory && _predictionHistory.isNotEmpty && _sessionStartTime != null) {
      try {
        final endTime = DateTime.now();
        final predictions = _predictionHistory.map<ActivityPrediction>((p) {
          final dynamic timestamp = p['timestamp'];
          final DateTime ts = (timestamp is DateTime)
              ? timestamp
              : (timestamp is int)
                  ? DateTime.fromMillisecondsSinceEpoch(timestamp)
                  : DateTime.now();
          return ActivityPrediction(
            activity: p['activity'] as String,
            confidence: p['confidence'] as double,
            timestamp: ts,
          );
        }).toList();

        final session = ActivitySession(
          id: '${_sessionStartTime!.millisecondsSinceEpoch}',
          startTime: _sessionStartTime!,
          endTime: endTime,
          predictions: predictions,
          summary: _getMostCommonActivity(),
        );

        // Save to local database
        await ref.read(activityStorageServiceProvider).saveSession(session);

        // Try to sync to remote Flask backend
        try {
          final api = ref.read(apiServiceProvider);
          final synced = await api.saveSessionRemote(session);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(synced
                    ? '✓ Session saved to backend & local storage'
                    : '⚠ Session saved locally (sync pending)'),
                backgroundColor: synced ? Colors.green : Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          if (kDebugMode) print('⚠ Failed to sync to backend: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Session saved locally (will sync when online)'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving session: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    if (mounted) {
      setState(() {
        _isMonitoring = false;
        _statusMessage = '✓ Monitoring stopped - ${_predictionHistory.length} predictions recorded';
        _isCollectingData = false;
      });
    }
  }

  String _getMostCommonActivity() {
    if (_predictionHistory.isEmpty) return 'Mixed';

    final activityCounts = <String, int>{};
    for (var prediction in _predictionHistory) {
      final activity = prediction['activity'] as String;
      activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
    }

    return activityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  void _resetSession() {
    setState(() {
      _currentActivity = 'Unknown';
      _confidence = 0.0;
      _stepCount = 0;
      _totalPredictions = 0;
      _predictionHistory.clear();
      _sessionStartTime = null;
      _accelerometerX.fillRange(0, _accelerometerX.length, 0.0);
      _accelerometerY.fillRange(0, _accelerometerY.length, 0.0);
      _accelerometerZ.fillRange(0, _accelerometerZ.length, 0.0);
      _statusMessage = 'Session reset';
      _isCollectingData = false;
      _isMonitoring = false;
    });
    _stopMonitoring(); // Ensure sensors are stopped and subscriptions cancelled
  }

  Widget _buildStatusIndicator() {
    Color color;
    String text;

    if (_isCollectingData) {
      color = TWColors.emerald500;
      text = 'Collecting data...';
    } else if (_isMonitoring) {
      color = TWColors.blue500;
      text = 'Monitoring paused';
    } else {
      color = TWColors.slate500;
      text = 'Inactive';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard() {
    final themeProvider = ref.watch(themeProviderProvider);

    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TWColors.emerald500.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'CURRENT ACTIVITY',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
                _buildStatusIndicator(),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _currentActivity,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: _getActivityColor(_currentActivity),
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _confidence,
              backgroundColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
              valueColor: AlwaysStoppedAnimation<Color>(
                _confidence > 0.7
                    ? TWColors.emerald500
                    : _confidence > 0.4
                    ? TWColors.amber500
                    : TWColors.red500,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
                Text(
                  '${(_confidence * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final themeProvider = ref.watch(themeProviderProvider);
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: screenWidth > 600 ? 1.2 : 1.3,
      children: [
        _buildStatCard(
          '$_stepCount',
          'Steps',
          Icons.directions_walk,
          TWColors.blue500,
          themeProvider,
        ),
        _buildStatCard(
          '$_totalPredictions',
          'Predictions',
          Icons.analytics,
          TWColors.emerald500,
          themeProvider,
        ),
        _buildStatCard(
          '${sessionDuration.inMinutes}:${(sessionDuration.inSeconds % 60).toString().padLeft(2, '0')}',
          'Duration',
          Icons.timer,
          TWColors.amber500,
          themeProvider,
        ),
        _buildStatCard(
          _isCollectingData ? '✓' : '✗',
          'Data Feed',
          Icons.sensors,
          _isCollectingData ? TWColors.emerald500 : TWColors.red500,
          themeProvider,
        ),
        _buildStatCard(
          _isMonitoring ? 'ON' : 'OFF',
          'Status',
          Icons.power_settings_new,
          _isMonitoring ? TWColors.emerald500 : TWColors.slate500,
          themeProvider,
        ),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color, ThemeProvider themeProvider) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeProvider.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: themeProvider.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: themeProvider.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionHistory() {
    final themeProvider = ref.watch(themeProviderProvider);

    if (_predictionHistory.isEmpty) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: themeProvider.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.history, size: 48, color: themeProvider.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                'No predictions yet',
                style: TextStyle(
                  fontSize: 16,
                  color: themeProvider.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start monitoring to see predictions',
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeProvider.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, size: 20, color: TWColors.blue500),
                const SizedBox(width: 8),
                Text(
                  'Recent Predictions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_predictionHistory.length} entries',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: _predictionHistory.length,
                itemBuilder: (context, index) {
                  final prediction = _predictionHistory[index];
                  final dynamic timestamp = prediction['timestamp'];
                  final DateTime time = (timestamp is DateTime) 
                      ? timestamp 
                      : (timestamp is int) 
                          ? DateTime.fromMillisecondsSinceEpoch(timestamp) 
                          : DateTime.now();
                  final activity = prediction['activity'] as String;
                  final confidence = prediction['confidence'] as double;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? TWColors.slate800 : TWColors.slate50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getActivityColor(activity),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activity,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: themeProvider.textPrimary,
                                ),
                              ),
                              Text(
                                DateFormat('HH:mm:ss').format(time),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: themeProvider.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(confidence).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${(confidence * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _getConfidenceColor(confidence),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataChart() {
    final themeProvider = ref.watch(themeProviderProvider);
    // Sensor data for chart is now directly from _accelerometerX,Y,Z buffers

    final List<FlSpot> xSpots = _accelerometerX.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final List<FlSpot> ySpots = _accelerometerY.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();
    final List<FlSpot> zSpots = _accelerometerZ.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeProvider.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.show_chart, size: 20, color: TWColors.purple500),
                const SizedBox(width: 8),
                Text(
                  'Accelerometer Data',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isCollectingData ? TWColors.emerald100 : TWColors.red100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isCollectingData ? 'ACTIVE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _isCollectingData ? TWColors.emerald700 : TWColors.red700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 150,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: 49,
                  minY: _minAccelerometer,
                  maxY: _maxAccelerometer,
                  gridData: FlGridData(
                    show: true,
                    drawHorizontalLine: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: themeProvider.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: themeProvider.textSecondary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: xSpots,
                      isCurved: true,
                      color: TWColors.blue500,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: ySpots,
                      isCurved: true,
                      color: TWColors.emerald500,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      spots: zSpots,
                      isCurved: true,
                      color: TWColors.amber500,
                      barWidth: 2,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAxisInfo('X', _accelerometerX.isNotEmpty ? _accelerometerX.last.toStringAsFixed(2) : '0.00', TWColors.blue500),
                _buildAxisInfo('Y', _accelerometerY.isNotEmpty ? _accelerometerY.last.toStringAsFixed(2) : '0.00', TWColors.emerald500),
                _buildAxisInfo('Z', _accelerometerZ.isNotEmpty ? _accelerometerZ.last.toStringAsFixed(2) : '0.00', TWColors.amber500),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAxisInfo(String axis, String value, Color color) {
    return Column(
      children: [
        Text(
          '$axis-axis',
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          'm/s²',
          style: TextStyle(
            fontSize: 10,
            color: TWColors.slate500,
          ),
        ),
      ],
    );
  }

  Widget _buildControlButtons() {
    final themeProvider = ref.watch(themeProviderProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: themeProvider.cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_isMonitoring || !_backendHealthy || !_modelLoaded)
                        ? null
                        : _startMonitoring,
                    icon: const Icon(Icons.play_arrow, size: 20),
                    label: const Text('Start Monitoring'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TWColors.emerald500,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: TWColors.slate400,
                      disabledForegroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isMonitoring ? _stopMonitoring : null,
                    icon: const Icon(Icons.stop, size: 20),
                    label: const Text('Stop'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: TWColors.red500),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _resetSession,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reset Session'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: themeProvider.textSecondary.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            if (!_backendHealthy || !_modelLoaded) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: TWColors.red500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: TWColors.red500.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, size: 16, color: TWColors.red500),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Backend unavailable. Check server status.',
                        style: TextStyle(
                          fontSize: 12,
                          color: TWColors.red500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _checkBackendStatus,
                      child: Text(
                        'Retry',
                        style: TextStyle(
                          fontSize: 12,
                          color: TWColors.blue500,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getActivityColor(String activity) {
    switch (activity.toLowerCase()) {
      case 'walking':
        return TWColors.blue600;
      case 'running':
        return TWColors.emerald600;
      case 'sitting':
        return TWColors.amber600;
      case 'standing':
        return TWColors.purple600;
      case 'cycling':
        return TWColors.indigo600;
      default:
        return TWColors.slate600;
    }
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence > 0.7) return TWColors.emerald600;
    if (confidence > 0.4) return TWColors.amber600;
    return TWColors.red600;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeProviderProvider);

    // React to activity predictions from the StreamProvider
    ref.listen<AsyncValue<ActivityModel>>(activityPredictionProvider, (prev, next) {
      next.whenData((activityModel) {
        if (mounted) {
          setState(() {
            _currentActivity = activityModel.activity;
            _confidence = activityModel.confidence;
            _totalPredictions++;
            _predictionHistory.insert(0, {
              'timestamp': DateTime.now(),
              'activity': activityModel.activity,
              'confidence': activityModel.confidence,
            });
            if (_predictionHistory.length > 20) {
              _predictionHistory.removeLast();
            }
            _statusMessage = '✓ ${activityModel.activity} (${(activityModel.confidence * 100).toStringAsFixed(0)}%)';
          });
          ref.read(currentActivityProvider.notifier).state = activityModel;
        }
      });
      next.whenOrNull(
        error: (error, stackTrace) {
          if (mounted) {
            setState(() {
              _statusMessage = '⚠ Prediction error: ${error.toString().split(':').last}';
              _backendError = error.toString();
              _modelStatus = 'error';
            });
          }
          if (kDebugMode) print('❌ Prediction error: $error\n$stackTrace');
        },
      );
    });

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Real-time Recognition',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Backend Connection Status Indicator
            const ConnectionStatusIndicator(showLabel: true),
          ],
        ),
        backgroundColor: themeProvider.cardColor,
        foregroundColor: themeProvider.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Message
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _backendError.isNotEmpty
                        ? (themeProvider.isDarkMode ? TWColors.red900 : TWColors.red50)
                        : (themeProvider.isDarkMode ? TWColors.blue900 : TWColors.blue50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _backendError.isNotEmpty ? Icons.error : Icons.info,
                            color: _backendError.isNotEmpty ? TWColors.red500 : TWColors.blue500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color: _backendError.isNotEmpty
                                    ? (themeProvider.isDarkMode ? TWColors.red300 : TWColors.red700)
                                    : (themeProvider.isDarkMode ? TWColors.blue300 : TWColors.blue700),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            _modelStatus == 'loaded'
                                ? Icons.check_circle
                                : _modelStatus == 'error'
                                    ? Icons.error
                                    : Icons.hourglass_empty,
                            size: 16,
                            color: _modelStatus == 'loaded'
                                ? TWColors.emerald500
                                : _modelStatus == 'error'
                                    ? TWColors.red500
                                    : TWColors.amber500,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Backend: ${_modelStatus == 'loaded' ? 'Ready' : _modelStatus == 'error' ? 'Unavailable' : 'Checking'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _backendError.isNotEmpty
                                  ? (themeProvider.isDarkMode ? TWColors.red300 : TWColors.red700)
                                  : (themeProvider.isDarkMode ? TWColors.blue300 : TWColors.blue700),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Sensor Buffering Progress
                const SensorBufferingProgressWidget(),
                const SizedBox(height: 20),

                // Activity Card
                _buildActivityCard(),
                const SizedBox(height: 20),

                // Stats Grid
                _buildStatsGrid(),
                const SizedBox(height: 20),

                // Prediction History
                _buildPredictionHistory(),
                const SizedBox(height: 20),

                // Sensor Data
                _buildSensorDataChart(),
                const SizedBox(height: 20),

                // Control Buttons
                _buildControlButtons(),
                const SizedBox(height: 20),

                // Info Text
                Text(
                  '© 2025 HARmony - Real-time Activity Recognition',
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _accelerometerStreamSubscription?.cancel();
    _gyroscopeStreamSubscription?.cancel();
    super.dispose();
  }
}
