import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class PrivacyDashboardScreen extends ConsumerWidget {
  const PrivacyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProviderProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Privacy & Ethical AI'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, size: 64, color: TWColors.indigo500),
              const SizedBox(height: 16),
              Text(
                'Privacy Dashboard',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'On-device only mode, view/delete data, explainable AI.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
