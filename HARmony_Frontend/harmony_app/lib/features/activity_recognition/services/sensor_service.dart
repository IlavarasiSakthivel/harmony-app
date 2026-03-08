import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';

/// Sampling at ~50 Hz; window of 40 samples for remote TFLite inference (120 floats: 40 samples × 3 axes).
class SensorService {
  static const Duration _samplingInterval = Duration(milliseconds: 20); // 50Hz
  static const int _windowSize = 40; // 40 samples × 3 axes = 120 floats for backend
  static const int _bufferCapacity = _windowSize * 3; // Allow some overflow

  final QueueList<AccelerometerEvent> _accBuffer = QueueList<AccelerometerEvent>();
  final QueueList<GyroscopeEvent> _gyroBuffer = QueueList<GyroscopeEvent>();

  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _gyroscopeSubscription;
  Timer? _inferenceTimer;
  bool _isRunning = false;

  final StreamController<SensorWindow> _sensorWindowController =
      StreamController<SensorWindow>.broadcast();
  final StreamController<SensorWindow> _inferenceReadyController =
      StreamController<SensorWindow>.broadcast();
  // Emit buffering progress: { 'samplesCollected': int, 'samplesNeeded': int }
  final StreamController<Map<String, int>> _bufferingProgressController =
      StreamController<Map<String, int>>.broadcast();

  Stream<SensorWindow> get sensorWindowStream => _sensorWindowController.stream;
  /// Emits when buffer has exactly 40 samples (and every 2s while running).
  Stream<SensorWindow> get inferenceReadyStream => _inferenceReadyController.stream;
  /// Emits current buffering progress as { 'samplesCollected': int, 'samplesNeeded': 40 }
  Stream<Map<String, int>> get bufferingProgressStream => _bufferingProgressController.stream;

  List<AccelerometerEvent> get accelerometerEvents =>
      List.from(_accBuffer);
  List<GyroscopeEvent> get gyroscopeEvents =>
      List.from(_gyroBuffer);
  bool get isRunning => _isRunning;
  int get currentBufferSize => _accBuffer.length;

  void startSensors() {
    if (kDebugMode) {
      debugPrint('SensorService: starting sensors (50Hz, window=$_windowSize samples = 120 floats)');
    }
    if (_accelerometerSubscription != null) return;
    _isRunning = true;

    _accelerometerSubscription = accelerometerEventStream(
      samplingPeriod: _samplingInterval,
    ).listen((event) {
      _accBuffer.add(event);
      // Keep buffer from growing unbounded
      while (_accBuffer.length > _bufferCapacity) _accBuffer.removeFirst();
      _emitBufferingProgress();
      _maybeEmitInferenceWindow();
    });

    _gyroscopeSubscription = gyroscopeEventStream(
      samplingPeriod: _samplingInterval,
    ).listen((event) {
      _gyroBuffer.add(event);
      // Keep buffer from growing unbounded
      while (_gyroBuffer.length > _bufferCapacity) _gyroBuffer.removeFirst();
      _emitBufferingProgress();
      _maybeEmitInferenceWindow();
    });

    _inferenceTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _maybeEmitInferenceWindow();
    });
  }

  void _emitBufferingProgress() {
    final progress = {
      'samplesCollected': _accBuffer.length,
      'samplesNeeded': _windowSize,
    };
    if (!_bufferingProgressController.isClosed) {
      _bufferingProgressController.add(progress);
    }
  }

  void _maybeEmitInferenceWindow() {
    if (_accBuffer.length >= _windowSize && _gyroBuffer.length >= _windowSize) {
      final accList = _accBuffer.take(_windowSize).toList();
      final gyroList = _gyroBuffer.take(_windowSize).toList();
      final window = SensorWindow.fromSensorData(
        timestamp: DateTime.now().millisecondsSinceEpoch,
        accelerometerEvents: accList,
        gyroscopeEvents: gyroList,
      );
      _sensorWindowController.add(window);
      _inferenceReadyController.add(window);
      // Remove the emitted window samples from buffer
      for (int i = 0; i < _windowSize && _accBuffer.isNotEmpty; i++) {
        _accBuffer.removeFirst();
      }
      for (int i = 0; i < _windowSize && _gyroBuffer.isNotEmpty; i++) {
        _gyroBuffer.removeFirst();
      }
      _emitBufferingProgress();
    }
  }

  void stopSensors() {
    if (kDebugMode) debugPrint('SensorService: stopping sensors');
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;
    _inferenceTimer?.cancel();
    _inferenceTimer = null;
    _accBuffer.clear();
    _gyroBuffer.clear();
    _isRunning = false;
  }

  void dispose() {
    stopSensors();
    _sensorWindowController.close();
    _inferenceReadyController.close();
    _bufferingProgressController.close();
  }
}
