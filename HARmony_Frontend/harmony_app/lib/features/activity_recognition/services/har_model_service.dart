// lib/features/activity_recognition/services/har_model_service.dart
import 'package:harmony_app/features/activity_recognition/services/model_loader.dart';

class HARModelService {
  final ModelLoader _modelLoader = ModelLoader();
  double _accuracy = 0.928; // 92.8% accuracy

  Future<void> initialize() async {
    await _modelLoader.initialize();
  }

  // These methods were likely missing or incorrect
  double get accuracy => _accuracy;

  List<String> getActivityNames() {
    return _modelLoader.getActivityNames();
  }

  Map<String, int> getActivityColors() {
    return {
      'Walking': 0xFF3B82F6,      // Blue
      'Walking Upstairs': 0xFF10B981,  // Green
      'Walking Downstairs': 0xFFF59E0B, // Amber
      'Sitting': 0xFF8B5CF6,      // Purple
      'Standing': 0xFF06B6D4,     // Cyan
      'Laying': 0xFF6366F1,       // Indigo
      'Unknown': 0xFF6B7280,      // Gray
    };
  }

  Map<String, String> getActivityIcons() {
    return {
      'Walking': '🚶',
      'Walking Upstairs': '⬆️',
      'Walking Downstairs': '⬇️',
      'Sitting': '🪑',
      'Standing': '🧍',
      'Laying': '🛌',
      'Unknown': '❓',
    };
  }

  void dispose() {

  }
}