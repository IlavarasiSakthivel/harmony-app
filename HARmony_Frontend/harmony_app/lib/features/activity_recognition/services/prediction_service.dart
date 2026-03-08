import 'dart:async';
import 'package:flutter/services.dart';

class PredictionService {
  static final PredictionService _instance = PredictionService._internal();
  factory PredictionService() => _instance;
  PredictionService._internal();

  final StreamController<Map<String, dynamic>> _predictionController =
  StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get predictionStream => _predictionController.stream;

  // Buffer for predictions
  List<Map<String, dynamic>> _predictionBuffer = [];
  final int _bufferSize = 10;

  // Current prediction with confidence
  Map<String, dynamic>? _currentPrediction;

  // Make prediction
  Future<void> predictActivity(List<double> features) async {
    try {
      // This is where you'd call your ML model
      // For now, simulate with method channel to native code

      final prediction = await _callNativeModel(features);

      // Add to buffer
      _predictionBuffer.add(prediction);
      if (_predictionBuffer.length > _bufferSize) {
        _predictionBuffer.removeAt(0);
      }

      // Apply voting/smoothing
      final smoothedPrediction = _smoothPredictions();

      _currentPrediction = smoothedPrediction;
      _predictionController.add(smoothedPrediction);

    } catch (e) {
      print('Prediction error: $e');
    }
  }

  // Call native code (Android/iOS) for ML inference
  Future<Map<String, dynamic>> _callNativeModel(List<double> features) async {
    // Method channel to native code
    const channel = MethodChannel('harmony_har/predict');

    try {
      final result = await channel.invokeMethod('predict', features);
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      print('Native model error: ${e.message}');

      // Fallback: Simple simulation
      return {
        'activity': 0,
        'activity_name': 'Walking',
        'confidence': 0.85,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }
  }

  // Smooth predictions using majority voting
  Map<String, dynamic> _smoothPredictions() {
    if (_predictionBuffer.isEmpty) {
      return {
        'activity': 0,
        'activity_name': 'Unknown',
        'confidence': 0.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    }

    // Count activities in buffer
    Map<int, int> activityCounts = {};
    double totalConfidence = 0.0;

    for (var pred in _predictionBuffer) {
      int activity = pred['activity'] ?? 0;
      activityCounts[activity] = (activityCounts[activity] ?? 0) + 1;
      totalConfidence += pred['confidence'] ?? 0.0;
    }

    // Find most frequent activity
    int mostFrequentActivity = 0;
    int maxCount = 0;

    activityCounts.forEach((activity, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentActivity = activity;
      }
    });

    // Average confidence
    double avgConfidence = totalConfidence / _predictionBuffer.length;

    return {
      'activity': mostFrequentActivity,
      'activity_name': _getActivityName(mostFrequentActivity),
      'confidence': avgConfidence,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  String _getActivityName(int activity) {
    const activityNames = {
      0: 'Walking',
      1: 'Walking Upstairs',
      2: 'Walking Downstairs',
      3: 'Sitting',
      4: 'Standing',
      5: 'Laying',
    };

    return activityNames[activity] ?? 'Unknown';
  }

  // Get current prediction
  Map<String, dynamic>? get currentPrediction => _currentPrediction;

  // Cleanup
  void dispose() {
    _predictionController.close();
  }
}