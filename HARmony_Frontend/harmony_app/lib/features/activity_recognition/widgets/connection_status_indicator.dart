import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/features/activity_recognition/services/backend_status_service.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

/// Widget that displays backend connection status with auto-updating indicator
class ConnectionStatusIndicator extends ConsumerWidget {
  final bool showLabel;
  final Size size;

  const ConnectionStatusIndicator({
    Key? key,
    this.showLabel = true,
    this.size = const Size(12, 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(backendConnectionStatusProvider).when(
      data: (status) => _buildStatusWidget(status),
      loading: () => _buildLoading(),
      error: (error, stack) => _buildError(),
    );
  }

  Widget _buildStatusWidget(BackendConnectionStatus status) {
    Color color;
    String label;
    String tooltip;

    switch (status) {
      case BackendConnectionStatus.connected:
        color = TWColors.emerald500;
        label = 'Connected';
        tooltip = 'Backend online - Model loaded';
        break;
      case BackendConnectionStatus.degraded:
        color = TWColors.amber500;
        label = 'Degraded';
        tooltip = 'Backend online - Model not loaded';
        break;
      case BackendConnectionStatus.connecting:
        color = TWColors.blue500;
        label = 'Connecting...';
        tooltip = 'Attempting to connect';
        break;
      case BackendConnectionStatus.disconnected:
        color = TWColors.red500;
        label = 'Disconnected';
        tooltip = 'Backend offline - Using local predictions';
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: status == BackendConnectionStatus.connecting
                ? Center(
                    child: SizedBox(
                      width: size.width - 2,
                      height: size.height - 2,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
          if (showLabel) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size.width,
          height: size.height,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(TWColors.blue500),
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          const Text(
            'Checking...',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TWColors.blue500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: TWColors.red500,
            shape: BoxShape.circle,
          ),
        ),
        if (showLabel) ...[
          const SizedBox(width: 8),
          const Text(
            'Error',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: TWColors.red500,
            ),
          ),
        ],
      ],
    );
  }
}
