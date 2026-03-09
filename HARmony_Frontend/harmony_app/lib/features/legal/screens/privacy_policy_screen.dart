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
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: themeProvider.cardColor,
        foregroundColor: themeProvider.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [TWColors.blue900, TWColors.purple900]
                      : [TWColors.blue100, TWColors.purple100],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Last Updated: March 8, 2026',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content Sections
            _buildSection(
              themeProvider,
              'Introduction',
              'HARmony ("we," "our," or "us") is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our Human Activity Recognition mobile application.',
            ),

            _buildSection(
              themeProvider,
              'Information We Collect',
              'HARmony collects and processes information to provide activity recognition services:\n\n'
              '• Sensor Data: Accelerometer and gyroscope data for activity recognition\n'
              '• Activity Data: Recognized activities (walking, running, sitting, standing)\n'
              '• Device Information: Basic device information for app functionality\n'
              '• User ID: Anonymous identifier for session management\n\n'
              'Sensor data is sent to our secure backend server for processing. We do not collect personal information such as your name, email, or precise location.',
            ),

            _buildSection(
              themeProvider,
              'How We Use Your Information',
              'We use the collected information for:\n\n'
              '• Activity Recognition: To identify and classify your physical activities using AI models\n'
              '• App Functionality: To provide real-time activity monitoring and analytics\n'
              '• Data Storage: To maintain your activity history for personal insights\n'
              '• Service Improvement: To improve our AI models and app performance\n\n'
              'All processing is done securely on our servers. We do not sell, trade, or share your data with third parties.',
            ),

            _buildSection(
              themeProvider,
              'Data Storage and Security',
              'Your data is stored securely:\n\n'
              '• Backend Storage: Activity data is stored on our secure PostgreSQL database\n'
              '• Local Cache: Recent data may be cached locally for offline functionality\n'
              '• Encryption: All data transmission uses HTTPS encryption\n'
              '• Access Control: Only you can access your data through the app\n\n'
              'We implement industry-standard security measures to protect your data.',
            ),

            _buildSection(
              themeProvider,
              'Permissions',
              'HARmony requires the following permissions:\n\n'
              '• Sensors: Access to accelerometer and gyroscope for activity detection\n'
              '• Activity Recognition: Permission to detect physical activities (Android 10+)\n'
              '• Internet: Required for backend processing and cloud features\n\n'
              'All permissions are essential for the app\'s core functionality.',
            ),

            _buildSection(
              themeProvider,
              'Your Rights',
              'You have the right to:\n\n'
              '• Access your data: View all stored activity data within the app\n'
              '• Delete your data: Request deletion of all your data from our servers\n'
              '• Data portability: Export your activity data in standard formats\n'
              '• Control permissions: Grant or revoke app permissions through device settings\n'
              '• Contact us: Reach out for any privacy concerns\n\n'
              'You can manage your data through the app settings or contact us directly.',
            ),

            // Data Controls Section
            Container(
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
                      Text(
                        'Data Controls',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: themeProvider.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You can request deletion of all your activity data from our servers at any time. Local cache data can be cleared through app settings. This action cannot be undone.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete all data?'),
                          content: const Text(
                            'This will request deletion of all your data from our servers and clear local cache. This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              style: TextButton.styleFrom(
                                foregroundColor: TWColors.red500,
                              ),
                              child: const Text('Delete'),
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
                            const SnackBar(
                              content: Text('All local data has been deleted'),
                              backgroundColor: TWColors.red500,
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Local Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TWColors.red500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _buildSection(
              themeProvider,
              'Children\'s Privacy',
              'HARmony is not intended for children under the age of 13. We do not knowingly collect information from children. If you are a parent or guardian and believe your child has provided us with information, please contact us.',
            ),

            _buildSection(
              themeProvider,
              'Contact Us',
              'If you have any questions about this Privacy Policy, please contact us:\n\n'
              'Email: privacy@harmony.app\n'
              'Website: www.harmony.app\n\n'
              'We are committed to addressing your privacy concerns promptly.',
            ),

            const SizedBox(height: 32),

            // Accept Button
            Container(
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
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(ThemeProvider themeProvider, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: themeProvider.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
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
}