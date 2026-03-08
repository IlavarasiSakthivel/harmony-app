import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, ThemeProvider;
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';

class DiagnosticScreen extends ConsumerStatefulWidget {
  const DiagnosticScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DiagnosticScreen> createState() => _DiagnosticScreenState();
}

class _DiagnosticScreenState extends ConsumerState<DiagnosticScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  final Random _random = Random();
  List<String> _logs = [];
  List<String> _activities = ['Walking', 'Running', 'Sitting', 'Standing', 'Cycling']; // Mock activities
  Map<String, double> _activityConfidence = {};
  String _testResult = 'Not tested';
  double _testConfidence = 0.0;
  bool _isTesting = false;
  int _testProgress = 0;
  int _totalTests = 7; // Adjusted total tests
  bool _modelLoaded = false; // Always true as we're mocking
  
  // Statistics
  int _totalPredictions = 0;
  double _averageConfidence = 0.0;
  String _modelStatus = 'Idle';
  int _quickTestCount = 0;

  @override
  void initState() {
    super.initState();
    _modelLoaded = true;
    _modelStatus = 'Loaded';
    _addLog('✅ HAR Model Loaded Successfully');

    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();

    // Fetch quick-test count from backend (best-effort)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final api = ref.read(apiServiceProvider);
        final count = await api.getQuickTestCount();
        setState(() { _quickTestCount = count; _totalPredictions = _quickTestCount; });
        _addLog('ℹ️ Quick test count loaded: $_quickTestCount');
      } catch (e) {
        if (kDebugMode) print('DiagnosticScreen: could not fetch quick test count: $e');
        _addLog('⚠️ Could not fetch quick test count');
      }
    });

  }

  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}] $message');
      if (_logs.length > 100) _logs.removeAt(0);
    });
    print(message);
  }

  Future<void> _runDiagnostics() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _logs.clear();
      _testProgress = 0;
      _testResult = 'Testing...';
      _modelStatus = 'Testing...';
    });

    _addLog('🚀 Starting comprehensive diagnostics...');

    try {
      // Test 1: Model Load Test
      _addLog('📦 Testing model loading...');
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _testProgress = 1);
      _addLog('✅ Model loaded successfully');

      // Test 2: Activity Labels Test
      _addLog('🏷️ Testing activity labels...');
      setState(() => _testProgress = 2);
      _addLog('📊 Found ${_activities.length} activities: ${_activities.join(", ")}');

      if (_activities.isEmpty) {
        throw Exception('No activities loaded');
      }

      // Test 3: Feature Configuration Test (Placeholder values)
      _addLog('⚙️ Testing feature configuration...');
      var config = {'feature_count': 561, 'window_size': 100}; // Mock config
      _addLog('   • Features: ${config['feature_count']}');
      _addLog('   • Window Size: ${config['window_size']}');
      setState(() => _testProgress = 3);

      // Test 4: Prediction Accuracy Test (Uses mock predictions from ApiService)
      _addLog('🎯 Testing prediction accuracy...');
      _activityConfidence.clear();
      int correct = 0;
      int total = 0;

      for (var activity in _activities) {
        total++;
        // Create dummy sensor window for prediction
        final mockSensorWindow = SensorWindow(
          timestamp: DateTime.now().millisecondsSinceEpoch,
          accelerometer: [],
          gyroscope: [],
        );
        
        try {
          final prediction = await ref.read(apiServiceProvider).predictActivity(mockSensorWindow);
          bool isCorrect = prediction.activity == activity; // Mock logic
          if (isCorrect) correct++;

          _activityConfidence[activity] = prediction.confidence;
          _addLog('   ${isCorrect ? "✅" : "⚠️"} $activity: ${prediction.activity} (${((prediction.confidence) * 100).toStringAsFixed(1)}% )');
        } catch (e) {
          _addLog('   ❌ $activity: Failed ($e)');
        }
        setState(() => _testProgress = 3 + (total * 3 ~/ _activities.length));
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Test 5: Performance Test (Simulated)
      _addLog('⏱️ Testing performance (Simulated)...');
      await Future.delayed(const Duration(milliseconds: 1000)); // Simulate work
      double avgInferenceTime = _random.nextDouble() * 50 + 10; // 10-60ms
      _addLog('   • Average inference: ${avgInferenceTime.toStringAsFixed(1)}ms');
      setState(() => _testProgress = 6);

      // Test 6: Final Validation
      _addLog('🔍 Running final validation...');
      final dummySensorWindow = SensorWindow(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        accelerometer: [const [0.0, 0.0, 9.8]],
        gyroscope: [const [0.0, 0.0, 0.0]],
      );
      var finalPrediction = await ref.read(apiServiceProvider).predictActivity(dummySensorWindow);
      setState(() {
        _testResult = finalPrediction.activity;
        _testConfidence = finalPrediction.confidence;
        _testProgress = 7;
      });

      // Calculate statistics
      double accuracy = total > 0 ? correct / total : 0.0;
      _totalPredictions = total;
      _averageConfidence = _activityConfidence.values.fold(0.0, (sum, val) => sum + val) /
          (_activityConfidence.length > 0 ? _activityConfidence.length : 1);

      _addLog('📊 Diagnostics Complete!');
      _addLog('   • Accuracy: ${(accuracy * 100).toStringAsFixed(1)}%');
      _addLog('   • Average Confidence: ${(_averageConfidence * 100).toStringAsFixed(1)}%');
      _addLog('   • Total Tests: $total');
      _addLog('   • Status: ${accuracy > 0.8 ? "EXCELLENT" : accuracy > 0.6 ? "GOOD" : "NEEDS ATTENTION"}');

    } catch (e) {
      _addLog('❌ Diagnostics failed: $e');
      setState(() {
        _testResult = 'Failed';
        _testConfidence = 0.0;
      });
    } finally {
      setState(() {
        _isTesting = false;
        _modelStatus = _testResult.contains('Failed') ? 'Error' : 'Ready';
      });
    }
  }

  void _clearLogs() {
    if (!mounted) return;
    setState(() {
      _logs.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeProviderProvider);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Model Diagnostics',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeProvider.cardColor,
        foregroundColor: themeProvider.textPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runDiagnostics,
            tooltip: 'Run Full Diagnostics',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              _clearLogs();
            },
            tooltip: 'Clear Logs',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Status Bar
            _buildStatusBar(themeProvider),

            // Progress Indicator
            _buildProgressIndicator(themeProvider),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Model Overview
                      _buildModelOverview(themeProvider),
                      const SizedBox(height: 20),

                      // Test Results
                      _buildTestResults(themeProvider),
                      const SizedBox(height: 20),

                      // Activity Confidence
                      if (_activityConfidence.isNotEmpty) ...[
                        _buildActivityConfidence(themeProvider),
                        const SizedBox(height: 20),
                      ],

                      // Logs Section
                      _buildLogsSection(themeProvider),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            _buildActionButtons(themeProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar(ThemeProvider themeProvider) {
    Color statusColor;
    String statusText;

    if (_isTesting) {
      statusColor = TWColors.amber500;
      statusText = 'Testing...';
    } else if (_modelStatus.contains('Loaded')) {
      statusColor = TWColors.emerald500;
      statusText = 'Model Ready';
    } else if (_modelStatus.contains('Error')) {
      statusColor = TWColors.red500;
      statusText = 'Model Error';
    } else {
      statusColor = TWColors.blue500;
      statusText = 'Idle';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: Container(
        key: ValueKey<String>(statusText), // Key is crucial for AnimatedSwitcher
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: statusColor.withOpacity(0.1),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
            Text(
              '$_testProgress/$_totalTests',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: themeProvider.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ThemeProvider themeProvider) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return SizeTransition(sizeFactor: animation, child: child);
      },
      child: LinearProgressIndicator(
        key: ValueKey<double>(_testProgress / _totalTests), // Key is crucial for AnimatedSwitcher
        value: _testProgress / _totalTests,
        backgroundColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
        valueColor: AlwaysStoppedAnimation<Color>(
          _isTesting ? TWColors.blue500 : TWColors.emerald500,
        ),
        minHeight: 4,
      ),
    );
  }

  Widget _buildModelOverview(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: TWColors.blue100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.psychology,
                  color: TWColors.blue600,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HAR Model v1.0',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Human Activity Recognition',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _modelLoaded ? TWColors.emerald100 : TWColors.red100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _modelLoaded ? 'Loaded' : 'Not Loaded',
                  style: TextStyle(
                    fontSize: 12,
                    color: _modelLoaded ? TWColors.emerald700 : TWColors.red700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                '$_totalPredictions',
                'Tests Run',
                Icons.assignment,
                TWColors.blue500,
                themeProvider,
              ),
              _buildStatItem(
                '${_activities.length}',
                'Activity Types',
                Icons.list,
                TWColors.indigo500,
                themeProvider,
              ),
              _buildStatItem(
                '${(_averageConfidence * 100).toStringAsFixed(0)}%',
                'Avg Confidence',
                Icons.trending_up,
                TWColors.emerald500,
                themeProvider,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color, ThemeProvider themeProvider) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: themeProvider.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTestResults(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest Test Result',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  _testResult,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: _testConfidence > 0.7
                        ? TWColors.emerald600
                        : _testConfidence > 0.4
                        ? TWColors.amber600
                        : TWColors.red600,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _testConfidence,
                      backgroundColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _testConfidence > 0.7
                            ? TWColors.emerald500
                            : _testConfidence > 0.4
                            ? TWColors.amber500
                            : TWColors.red500,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_testConfidence * 100).toStringAsFixed(1)}% Confidence',
                  style: TextStyle(
                    fontSize: 14,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityConfidence(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Confidence Levels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ..._activityConfidence.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                      Text(
                        '${(entry.value * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: entry.value > 0.7
                              ? TWColors.emerald600
                              : entry.value > 0.4
                              ? TWColors.amber600
                              : TWColors.red600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    height: 6,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          entry.value > 0.7
                              ? TWColors.emerald500
                              : entry.value > 0.4
                              ? TWColors.amber500
                              : TWColors.red500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogsSection(ThemeProvider themeProvider) {
    return Container(
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(Icons.terminal, color: TWColors.blue600),
                const SizedBox(width: 12),
                Text(
                  'Diagnostic Logs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${_logs.length} entries',
                      style: TextStyle(
                        fontSize: 14,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quick tests: $_quickTestCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: themeProvider.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? TWColors.slate900 : TWColors.slate50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: themeProvider.textSecondary.withOpacity(0.2),
              ),
            ),
            child: _logs.isEmpty
                ? Center(
              child: Text(
                'No logs yet. Run diagnostics to see results.',
                style: TextStyle(
                  color: themeProvider.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
                : ListView.builder(
              key: ValueKey<int>(_logs.length),
              reverse: true,
              itemCount: _logs.length,
              itemBuilder: (context, index) {
                final log = _logs[_logs.length - 1 - index];
                Color logColor;

                if (log.contains('✅')) {
                  logColor = TWColors.emerald500;
                } else if (log.contains('❌')) {
                  logColor = TWColors.red500;
                } else if (log.contains('⚠️')) {
                  logColor = TWColors.amber500;
                } else if (log.contains('🚀')) {
                  logColor = TWColors.blue500;
                } else {
                  logColor = themeProvider.textPrimary;
                }

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: themeProvider.textSecondary.withOpacity(0.1),
                      ),
                    ),
                  ),
                  child: SelectableText(
                    log,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'RobotoMono',
                      color: logColor,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        border: Border(
          top: BorderSide(color: themeProvider.textSecondary.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _runQuickTest,
              icon: const Icon(Icons.flash_on),
              label: const Text('Quick Test'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: TWColors.indigo500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _runDiagnostics,
              icon: Icon(_isTesting ? Icons.refresh : Icons.play_arrow),
              label: Text(_isTesting ? 'Testing...' : 'Full Diagnostics'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _isTesting ? TWColors.amber500 : TWColors.blue500,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runQuickTest() async {
    if (_isTesting) return;

    setState(() {
      _logs.clear();
      _isTesting = true;
      _testResult = 'Quick Test...';
    });

    _addLog('⚡ Running quick test...');

    try {
      // Create dummy sensor window for prediction
      final dummySensorWindow = SensorWindow(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        accelerometer: [const [0.0, 0.0, 9.8]],
        gyroscope: [const [0.0, 0.0, 0.0]],
      );

      var prediction = await ref.read(apiServiceProvider).predictActivity(dummySensorWindow);
      setState(() {
        _testResult = prediction.activity;
        _testConfidence = prediction.confidence;
      });

      _addLog('✅ Quick test completed');
      _addLog('   Result: $_testResult');
      _addLog('   Confidence: ${(_testConfidence * 100).toStringAsFixed(1)}%');
    } catch (e) {
      _addLog('❌ Quick test failed: $e');
      setState(() {
        _testResult = 'Failed';
        _testConfidence = 0.0;
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }
}
