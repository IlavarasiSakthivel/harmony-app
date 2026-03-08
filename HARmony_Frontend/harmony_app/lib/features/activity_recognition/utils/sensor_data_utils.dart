import 'package:harmony_app/features/activity_recognition/models/sensor_window.dart';

/// Utility class for sensor data transformation and validation.
class SensorDataUtils {
  /// Expected number of floats in flattened sensor data (40 samples × 3 axes).
  static const int expectedFlatSize = 120;

  /// Flatten a SensorWindow's accelerometer data into a single list of floats.
  /// Takes the first 40 samples if more are available.
  /// Returns exactly 120 floats: [x1, y1, z1, x2, y2, z2, ..., x40, y40, z40]
  static List<double> flattenSensorWindow(SensorWindow window) {
    final List<double> flattened = [];
    final int samplesToTake = window.accelerometer.length >= 40 ? 40 : window.accelerometer.length;

    for (int i = 0; i < samplesToTake; i++) {
      final sample = window.accelerometer[i];
      flattened.add(sample[0]); // x
      flattened.add(sample[1]); // y
      flattened.add(sample[2]); // z
    }

    // Pad with zeros if we have fewer than 40 samples (shouldn't happen in normal operation)
    while (flattened.length < expectedFlatSize) {
      flattened.add(0.0);
    }

    return flattened;
  }

  /// Validate that flattened sensor data has exactly the expected size.
  static bool isValidFlatSize(List<double> flatData) {
    return flatData.length == expectedFlatSize;
  }

  /// Get validation error message for invalid sensor data.
  static String getValidationErrorMessage(List<double> flatData) {
    if (flatData.isEmpty) {
      return 'No sensor data to send.';
    }
    if (flatData.length != expectedFlatSize) {
      return 'Need exactly $expectedFlatSize sensor values (40x3). Got ${flatData.length}.';
    }
    return '';
  }
}

