import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';

/// Widget to display prediction results including confidence and top probabilities.
class PredictionResultWidget extends ConsumerWidget {
  final String activity;
  final double confidence;
  final Map<String, double>? allProbabilities;

  const PredictionResultWidget({
    Key? key,
    required this.activity,
    required this.confidence,
    this.allProbabilities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Confidence score
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'CONFIDENCE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: themeProvider.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              '${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _getConfidenceColor(confidence),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Linear progress indicator for confidence
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: confidence,
            minHeight: 6,
            backgroundColor: themeProvider.isDarkMode
                ? TWColors.slate700
                : TWColors.slate200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _getConfidenceColor(confidence),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Top probabilities from all_probabilities if available
        if (allProbabilities != null && allProbabilities!.isNotEmpty)
          _buildProbabilityChart(themeProvider, allProbabilities!)
        else
          const SizedBox.shrink(),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return TWColors.emerald500;
    if (confidence >= 0.6) return TWColors.amber500;
    return TWColors.red500;
  }

  Widget _buildProbabilityChart(
      ThemeProvider themeProvider, Map<String, double> probs) {
    // Sort probabilities descending and take top 5
    final sorted = probs.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topProbs = sorted.take(5).toList();

    if (topProbs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOP PROBABILITIES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: themeProvider.textSecondary,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        ...topProbs.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeProvider.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: entry.value,
                      minHeight: 5,
                      backgroundColor: themeProvider.isDarkMode
                          ? TWColors.slate700
                          : TWColors.slate200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        TWColors.blue500.withOpacity(0.7),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    '${(entry.value * 100).toStringAsFixed(0)}%',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

