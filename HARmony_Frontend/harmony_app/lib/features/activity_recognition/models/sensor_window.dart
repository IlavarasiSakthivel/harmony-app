
import 'package:json_annotation/json_annotation.dart';
import 'package:sensors_plus/sensors_plus.dart';

part 'sensor_window.g.dart';

@JsonSerializable()
class SensorWindow {
  final int timestamp; // Timestamp of the window in milliseconds
  final List<List<double>> accelerometer; // List of [x,y,z] for each sample
  final List<List<double>> gyroscope; // List of [x,y,z] for each sample

  SensorWindow({
    required this.timestamp,
    required this.accelerometer,
    required this.gyroscope,
  });

  factory SensorWindow.fromJson(Map<String, dynamic> json) => _$SensorWindowFromJson(json);
  Map<String, dynamic> toJson() => _$SensorWindowToJson(this);

  // Helper to create a SensorWindow from raw sensor data
  static SensorWindow fromSensorData({
    required int timestamp,
    required List<AccelerometerEvent> accelerometerEvents,
    required List<GyroscopeEvent> gyroscopeEvents,
  }) {
    return SensorWindow(
      timestamp: timestamp,
      accelerometer: accelerometerEvents.map((e) => [e.x, e.y, e.z]).toList(),
      gyroscope: gyroscopeEvents.map((e) => [e.x, e.y, e.z]).toList(),
    );
  }
}
