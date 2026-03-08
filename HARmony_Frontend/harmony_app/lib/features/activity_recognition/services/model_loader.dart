/// Minimal model loader for HAR model info (activity names, feature config).
/// On-device inference uses [ModelInferenceService] and [har_model.tflite].
class ModelLoader {
  bool _isInitialized = false;
  List<String> _activityNames = [];
  Map<String, dynamic> _featureConfig = {};

  Future<void> initialize() async {
    if (_isInitialized) return;
    _activityNames = getDefaultActivities();
    _featureConfig = {
      'feature_count': 128 * 9,
      'window_size': 128,
      'sampling_rate': 50,
      'model_type': 'TFLite',
      'activities_count': _activityNames.length,
      'model_loaded': true,
      'backend_connected': false,
    };
    _isInitialized = true;
  }

  List<String> getDefaultActivities() => [
        'Walking',
        'Walking Upstairs',
        'Walking Downstairs',
        'Sitting',
        'Standing',
        'Laying',
      ];

  List<String> getActivityNames() => _activityNames;
  Map<String, dynamic> getFeatureConfig() => Map.from(_featureConfig);
  bool get isInitialized => _isInitialized;
}
