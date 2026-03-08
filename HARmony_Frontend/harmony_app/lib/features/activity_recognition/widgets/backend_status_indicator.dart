import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

/// Widget that displays the backend model status (Green: loaded, Red: not loaded/error).
/// Shows cached health status without blocking UI.
class BackendStatusIndicator extends ConsumerWidget {
  const BackendStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthAsync = ref.watch(healthCheckProvider);

    return healthAsync.when(
      data: (health) {
        final isLoaded = health.modelLoaded && health.isHealthy;
        final color = isLoaded ? TWColors.emerald500 : TWColors.red500;
        final tooltip = isLoaded
            ? 'Backend model loaded'
            : 'Backend model not loaded: ${health.message ?? "unknown error"}';

        return Tooltip(
          message: tooltip,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
      loading: () {
        return Tooltip(
          message: 'Checking backend status...',
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: TWColors.amber500,
              shape: BoxShape.circle,
            ),
            child: const SizedBox.expand(
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        );
      },
      error: (err, stack) {
        return Tooltip(
          message: 'Backend unavailable',
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: TWColors.red500,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

