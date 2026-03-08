import 'package:flutter/material.dart';
import 'package:harmony_app/features/activity_recognition/models/activity_model.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

const double predictionWindowSeconds = 2.0;

String normalizeActivityLabel(String label) {
  if (label.isEmpty) return 'Unknown';
  final lower = label.toLowerCase();
  if (lower.contains('walk')) return 'Walking';
  if (lower.contains('run') || lower.contains('jog')) return 'Running';
  if (lower.contains('cycle') || lower.contains('bike')) return 'Cycling';
  if (lower.contains('stand')) return 'Standing';
  if (lower.contains('sit')) return 'Sitting';
  if (lower.contains('lay') || lower.contains('sleep')) return 'Sleeping';
  return label[0].toUpperCase() + label.substring(1);
}

bool isActiveActivity(String label) {
  final normalized = normalizeActivityLabel(label);
  return normalized == 'Walking' ||
      normalized == 'Running' ||
      normalized == 'Cycling';
}

Color activityColor(String label) {
  final normalized = normalizeActivityLabel(label);
  switch (normalized) {
    case 'Walking':
      return TWColors.emerald500;
    case 'Running':
      return TWColors.red400;
    case 'Cycling':
      return TWColors.blue500;
    case 'Standing':
      return TWColors.amber500;
    case 'Sitting':
      return TWColors.slate500;
    case 'Sleeping':
      return TWColors.indigo500;
    default:
      return TWColors.purple400;
  }
}

int estimateActiveMinutesFromPredictions(List<ActivityPrediction> predictions) {
  if (predictions.isEmpty) return 0;
  final activeCount = predictions.where((p) => isActiveActivity(p.activity)).length;
  return (activeCount * predictionWindowSeconds / 60).round();
}

int estimateInactiveMinutesFromPredictions(List<ActivityPrediction> predictions) {
  if (predictions.isEmpty) return 0;
  final inactiveCount = predictions.where((p) => !isActiveActivity(p.activity)).length;
  return (inactiveCount * predictionWindowSeconds / 60).round();
}

Map<String, int> activityDistribution(List<ActivityPrediction> predictions) {
  final counts = <String, int>{};
  for (final p in predictions) {
    final label = normalizeActivityLabel(p.activity);
    counts[label] = (counts[label] ?? 0) + 1;
  }
  return counts;
}

List<ActivityPrediction> flattenPredictions(List<ActivitySession> sessions) {
  return sessions.expand((s) => s.predictions).toList();
}
