import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';

class FuturisticScreen extends ConsumerWidget {
  const FuturisticScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProviderProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Future Scope'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildHeader(theme),
          const SizedBox(height: 16),
          _buildFeatureCard(theme, 'Gyroscope Fusion', 'Combine accelerometer + gyro for richer motion signatures.', 'Planned', TWColors.blue500),
          _buildFeatureCard(theme, 'Cloud Analytics', 'Long-term trend insights with secure sync.', 'Research', TWColors.indigo500),
          _buildFeatureCard(theme, 'Wearable Integration', 'Smartwatch + fitness tracker signals in real-time.', 'Prototype', TWColors.emerald500),
          _buildFeatureCard(theme, 'AI Health Predictions', 'Early warning for sedentary risk and fatigue.', 'Planned', TWColors.purple500),
          _buildFeatureCard(theme, 'Smart Home Integration', 'Context-aware lighting and reminders.', 'Exploring', TWColors.amber500),
          const SizedBox(height: 16),
          _buildTimeline(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Innovation Roadmap', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600, fontSize: 18)),
            const SizedBox(height: 8),
            Text('A clear path from on-device intelligence to connected health ecosystems.', style: TextStyle(color: theme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(ThemeProvider theme, String title, String description, String status, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.only(top: 6),
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description, style: TextStyle(color: theme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Roadmap Timeline', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            _timelineItem(theme, 'Q2 2026', 'Gyroscope fusion + improved confidence calibration'),
            _timelineItem(theme, 'Q3 2026', 'Wearable pairing & background activity sync'),
            _timelineItem(theme, 'Q4 2026', 'Cloud dashboards and smart home routines'),
          ],
        ),
      ),
    );
  }

  Widget _timelineItem(ThemeProvider theme, String time, String detail) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(color: TWColors.purple500, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(time, style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(detail, style: TextStyle(color: theme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
