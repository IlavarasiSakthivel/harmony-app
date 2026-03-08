import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider;
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class ActivityCard extends ConsumerWidget {
  final String activity;
  final double confidence;
  final int stepCount;
  final bool isActive;
  final VoidCallback? onTap;

  const ActivityCard({
    Key? key,
    required this.activity,
    required this.confidence,
    required this.stepCount,
    this.isActive = false,
    this.onTap,
  }) : super(key: key);

  String getActivityEmoji(String activity) {
    switch (activity.toUpperCase()) {
      case 'WALKING':
        return '🚶';
      case 'WALKING_UPSTAIRS':
        return '⬆️';
      case 'WALKING_DOWNSTAIRS':
        return '⬇️';
      case 'SITTING':
        return '🪑';
      case 'STANDING':
        return '🧍';
      case 'LAYING':
        return '🛌';
      default:
        return '❓';
    }
  }

  Color getActivityColor(String activity) {
    switch (activity.toUpperCase()) {
      case 'WALKING':
        return TWColors.blue500; // Blue
      case 'WALKING_UPSTAIRS':
        return TWColors.emerald500; // Green
      case 'WALKING_DOWNSTAIRS':
        return TWColors.purple500; // Purple
      case 'SITTING':
        return TWColors.amber500; // Amber
      case 'STANDING':
        return TWColors.red500; // Red
      case 'LAYING':
        return TWColors.pink500; // Pink
      default:
        return TWColors.slate500; // Slate
    }
  }

  String getFormattedActivity(String activity) {
    switch (activity.toUpperCase()) {
      case 'WALKING':
        return 'Walking';
      case 'WALKING_UPSTAIRS':
        return 'Walking Upstairs';
      case 'WALKING_DOWNSTAIRS':
        return 'Walking Downstairs';
      case 'SITTING':
        return 'Sitting';
      case 'STANDING':
        return 'Standing';
      case 'LAYING':
        return 'Laying Down';
      default:
        return activity;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final backgroundColor = themeProvider.cardColor;
    final textPrimary = themeProvider.textPrimary;
    final textSecondary = themeProvider.textSecondary;

    final emoji = getActivityEmoji(activity);
    final color = getActivityColor(activity);
    final formattedActivity = getFormattedActivity(activity);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CURRENT ACTIVITY',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: textSecondary,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            formattedActivity,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive
                          ? TWColors.emerald500.withOpacity(0.1)
                          : TWColors.red500.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'ACTIVE' : 'INACTIVE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? TWColors.emerald500
                            : TWColors.red500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Confidence Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Confidence',
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: confidence,
                      minHeight: 8,
                      backgroundColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Divider
              Divider(
                color: textSecondary.withOpacity(0.1),
                height: 1,
              ),
              const SizedBox(height: 20),

              // Steps and Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step Count',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepCount.toString(),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Model Version',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'v2.1',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Last Updated',
                        style: TextStyle(
                          fontSize: 10,
                          color: textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Just now',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
