// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sensor_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SensorWindow _$SensorWindowFromJson(Map<String, dynamic> json) => SensorWindow(
  timestamp: (json['timestamp'] as num).toInt(),
  accelerometer: (json['accelerometer'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
  gyroscope: (json['gyroscope'] as List<dynamic>)
      .map(
        (e) => (e as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      )
      .toList(),
);

Map<String, dynamic> _$SensorWindowToJson(SensorWindow instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'accelerometer': instance.accelerometer,
      'gyroscope': instance.gyroscope,
    };
