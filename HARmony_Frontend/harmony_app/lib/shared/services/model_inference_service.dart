import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;

import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';

/// Result of on-device inference: activity label, confidence, and full probability vector.
class ModelPrediction {
  final String activity;
  final double confidence;
  final List<double> probabilities;

  const ModelPrediction({
    required this.activity,
    required this.confidence,
    required this.probabilities,
  });

  ActivityPrediction toActivityPrediction() => ActivityPrediction(
        activity: activity,
        confidence: confidence,
        timestamp: DateTime.now(),
      );

  ActivityModel toActivityModel() => ActivityModel(
        activity: activity,
        confidence: confidence,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
}

/// Loads the on-device TFLite HAR model and runs inference on 128×9 sensor windows.
///
/// Expects input shape [1, 128, 9] (1 batch, 128 timesteps, 9 channels: accel x,y,z + gyro x,y,z).
/// Output: [1, numClasses] logits or probabilities; we treat as probabilities and take argmax.
class ModelInferenceService {
  static const String _modelAssetPath = 'assets/har_model.tflite';

  /// Normalization: (x - mean) / std per channel. Tune to match your training.
  static const List<double> _mean = [
    0.0, 0.0, 9.8, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
  ];
  static const List<double> _std = [
    3.0, 3.0, 3.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0,
  ];

  static const List<String> _defaultLabels = [
    'Walking',
    'Walking Upstairs',
    'Walking Downstairs',
    'Sitting',
    'Standing',
    'Laying',
  ];

  tfl.Interpreter? _interpreter;
  bool _isLoading = false;
  Object? _lastError;
  List<String> _labels = List.from(_defaultLabels);

  bool get isLoaded => _interpreter != null;
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  List<String> get labels => List.unmodifiable(_labels);

  Future<void> loadModel({List<String>? labelsOverride}) async {
    if (_interpreter != null) return;
    if (_isLoading) return;

    _isLoading = true;
    _lastError = null;

    try {
      if (kDebugMode) {
        debugPrint('[ModelInferenceService] Loading $_modelAssetPath');
      }
      _interpreter = await tfl.Interpreter.fromAsset(_modelAssetPath);
      if (labelsOverride != null && labelsOverride.isNotEmpty) {
        _labels = List.from(labelsOverride);
      }
      if (kDebugMode) {
        final inputShape = _interpreter!.getInputTensor(0).shape;
        final outputShape = _interpreter!.getOutputTensor(0).shape;
        debugPrint('[ModelInferenceService] Input: $inputShape, Output: $outputShape');
      }
    } catch (e, st) {
      _lastError = e;
      if (kDebugMode) debugPrint('[ModelInferenceService] Load error: $e\n$st');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
  }

  /// Preprocess [SensorWindow] into [1, 128, 9] float32.
  /// Window must have at least 128 samples; we take the first 128.
  List<List<List<double>>> _preprocessWindow(SensorWindow window) {
    const int steps = 128;
    const int channels = 9;
    final acc = window.accelerometer;
    final gyro = window.gyroscope;
    final n = acc.length < steps ? acc.length : steps;
    if (n < steps && kDebugMode) {
      debugPrint('[ModelInferenceService] Window has $n samples, expected $steps');
    }

    final input = List.generate(
      1,
      (_) => List.generate(
            steps,
            (t) => List.generate(channels, (c) => 0.0),
          ),
    );

    for (int t = 0; t < n && t < steps; t++) {
      for (int i = 0; i < 3 && i < (acc[t].length); i++) {
        input[0][t][i] = ((acc[t][i] - _mean[i]) / _std[i]);
      }
      for (int i = 0; i < 3 && i < (gyro[t].length); i++) {
        input[0][t][3 + i] = ((gyro[t][i] - _mean[3 + i]) / _std[3 + i]);
      }
      for (int i = 6; i < channels; i++) {
        input[0][t][i] = 0.0;
      }
    }
    return input;
  }

  ModelPrediction _postprocess(List<double> logitsOrProbs) {
    double maxVal = logitsOrProbs.isNotEmpty ? logitsOrProbs[0] : 0.0;
    int argmax = 0;
    for (int i = 1; i < logitsOrProbs.length; i++) {
      if (logitsOrProbs[i] > maxVal) {
        maxVal = logitsOrProbs[i];
        argmax = i;
      }
    }
    // Optional: softmax if model outputs logits. For many HAR models output is already softmax.
    double sum = 0.0;
    for (final v in logitsOrProbs) {
      sum += v;
    }
    final probs = sum > 0 && sum < 100
        ? logitsOrProbs.map((e) => e / sum).toList()
        : List.filled(logitsOrProbs.length, 1.0 / logitsOrProbs.length);
    final confidence = argmax < probs.length ? probs[argmax] : 0.0;
    final labelIndex = argmax < _labels.length ? argmax : 0;
    final activity = _labels[labelIndex];
    return ModelPrediction(
      activity: activity,
      confidence: confidence.clamp(0.0, 1.0),
      probabilities: probs,
    );
  }

  /// Run inference on [window]. Loads model on first call if needed.
  Future<ModelPrediction> runWindow(SensorWindow window) async {
    if (_interpreter == null) {
      await loadModel();
    }
    final interpreter = _interpreter;
    if (interpreter == null) {
      throw StateError('TFLite model not loaded');
    }

    final input = _preprocessWindow(window);
    final outputTensor = interpreter.getOutputTensor(0);
    final numClasses = outputTensor.shape.last;
    final output = [List.filled(numClasses, 0.0)];
    interpreter.run(input, output);
    return _postprocess(output[0]);
  }
}
