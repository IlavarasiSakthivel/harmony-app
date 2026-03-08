import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider;

class PrivacyPolicyScreen extends ConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeProvider = ref.watch(themeProviderProvider);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: themeProvider.cardColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: themeProvider.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Privacy Policy',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [TWColors.blue900, TWColors.purple900]
                        : [TWColors.blue100, TWColors.purple100],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -50,
                      right: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TWColors.blue500.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: TWColors.purple500.withOpacity(0.1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    themeProvider,
                    'Last Updated: February 18, 2026',
                    'Introduction',
                    'HARmony ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our Human Activity Recognition mobile application.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Information We Collect',
                    'Data Collection',
                    'HARmony is designed with privacy in mind. We collect minimal information:\n\n'
                    '• Sensor Data: Accelerometer and gyroscope data for activity recognition\n'
                    '• Activity Data: Recognized activities (walking, running, sitting, standing)\n'
                    '• Device Information: Basic device information for app functionality\n\n'
                    'All data processing happens locally on your device. We do not collect personal information such as your name, email, or location.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'How We Use Your Information',
                    'Usage',
                    'We use the collected information solely for:\n\n'
                    '• Activity Recognition: To identify and classify your physical activities\n'
                    '• App Functionality: To provide real-time activity monitoring features\n'
                    '• Local Storage: To maintain your activity history on your device\n\n'
                    'We do not sell, trade, or share your data with third parties.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Data Usage & Ethics',
                    'Transparency',
                    'HARmony is designed for wellness insights, not medical diagnosis. We avoid sensitive personal data and use sensor signals only to classify activity types. Any insights are presented as guidance, not clinical advice.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Data Storage',
                    'Storage',
                    'All activity data is stored locally on your device:\n\n'
                    '• No cloud storage: Your data never leaves your device\n'
                    '• Local database: Activity history is stored in device storage\n'
                    '• User control: You can clear your data at any time through app settings\n\n'
                    'We do not have access to your stored data.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Permissions',
                    'App Permissions',
                    'HARmony requires the following permissions:\n\n'
                    '• Sensors: Access to accelerometer and gyroscope for activity detection\n'
                    '• Activity Recognition: Permission to detect physical activities (Android 10+)\n'
                    '• Internet: Optional, only if you choose to connect to a backend server\n\n'
                    'All permissions are used exclusively for app functionality.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Your Rights',
                    'User Rights',
                    'You have the right to:\n\n'
                    '• Access your data: View all stored activity data within the app\n'
                    '• Delete your data: Clear all activity history at any time\n'
                    '• Control permissions: Grant or revoke app permissions through device settings\n'
                    '• Uninstall: Remove the app and all associated data by uninstalling\n\n'
                    'Since all data is stored locally, you have complete control.',
                  ),
                  const SizedBox(height: 24),
                  _buildDataControls(context, ref, themeProvider),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Children\'s Privacy',
                    'Children',
                    'HARmony is not intended for children under the age of 13. We do not knowingly collect information from children. If you are a parent or guardian and believe your child has provided us with information, please contact us.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Changes to This Policy',
                    'Updates',
                    'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last Updated" date. You are advised to review this Privacy Policy periodically for any changes.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Contact Us',
                    'Contact',
                    'If you have any questions about this Privacy Policy, please contact us:\n\n'
                    'Email: privacy@harmony.app\n'
                    'Website: www.harmony.app\n\n'
                    'We are committed to addressing your privacy concerns promptly.',
                  ),
                  const SizedBox(height: 32),
                  _buildAcceptButton(context, themeProvider),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    String subtitle,
    String content,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TWColors.blue500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.privacy_tip,
                  color: TWColors.blue500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: TWColors.blue500,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: themeProvider.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataControls(BuildContext context, WidgetRef ref, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TWColors.red500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: TWColors.red500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Data Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You can delete all locally stored activity sessions and sensor snapshots at any time. This action cannot be undone.',
            style: TextStyle(fontSize: 15, height: 1.6, color: themeProvider.textSecondary),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete all data?'),
                  content: const Text('This will remove all local activity history and sensor snapshots.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete', style: TextStyle(color: TWColors.red500)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                final storage = ref.read(activityStorageServiceProvider);
                await storage.clearAllSessions();
                await storage.clearSensorSnapshots();
                await storage.clearCoachAlerts();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Local data deleted')),
                  );
                }
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Delete Local Data'),
            style: ElevatedButton.styleFrom(backgroundColor: TWColors.red500, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TWColors.blue500, TWColors.purple500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TWColors.blue500.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'I Understand',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
