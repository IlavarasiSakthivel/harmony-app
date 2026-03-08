import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';

/// Widget to display the current buffering progress (e.g., "27/40 samples collected").
class SensorBufferingProgressWidget extends ConsumerWidget {
  const SensorBufferingProgressWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sensorService = ref.watch(sensorServiceProvider);
    final themeProvider = ref.watch(themeProviderProvider);
    final progressStream = sensorService.bufferingProgressStream;

    return StreamBuilder<Map<String, int>>(
      stream: progressStream,
      initialData: {
        'samplesCollected': sensorService.currentBufferSize,
        'samplesNeeded': 40,
      },
      builder: (context, snapshot) {
        final data = snapshot.data ?? {};
        final collected = data['samplesCollected'] ?? 0;
        final needed = data['samplesNeeded'] ?? 40;
        final progress = (collected / needed).clamp(0.0, 1.0);

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode
                ? TWColors.slate800
                : TWColors.slate100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (collected >= needed)
                  ? TWColors.emerald500.withOpacity(0.3)
                  : TWColors.blue500.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'INPUT WINDOW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    '$collected/$needed samples',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: (collected >= needed)
                          ? TWColors.emerald500
                          : TWColors.blue500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: themeProvider.isDarkMode
                      ? TWColors.slate700
                      : TWColors.slate200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    (collected >= needed)
                        ? TWColors.emerald500
                        : TWColors.blue500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

