import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show ThemeProvider, themeProviderProvider;
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class HelpSupportScreen extends ConsumerWidget {
  const HelpSupportScreen({super.key});

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
                'Help & Support',
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
                        ? [TWColors.emerald900, TWColors.teal900]
                        : [TWColors.emerald100, TWColors.teal100],
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
                          color: TWColors.emerald500.withOpacity(0.1),
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
                          color: TWColors.teal500.withOpacity(0.1),
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
                  _buildQuickActions(context, themeProvider),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Getting Started',
                    Icons.play_circle_filled,
                    TWColors.blue500,
                    [
                      _buildFAQItem(
                        themeProvider,
                        'How do I start activity recognition?',
                        'Tap the "Real-time Monitoring" button on the home screen or use the bottom navigation. The app will automatically start detecting your activities using device sensors.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'What activities can HARmony detect?',
                        'HARmony can detect walking, running, sitting, and standing activities with high accuracy using machine learning models.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'Do I need an internet connection?',
                        'No! HARmony works completely offline. All processing happens locally on your device. Internet is only needed if you choose to connect to an optional backend server.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Troubleshooting',
                    Icons.build,
                    TWColors.amber500,
                    [
                      _buildFAQItem(
                        themeProvider,
                        'Why is activity recognition not working?',
                        'Make sure you have granted sensor permissions. Go to Settings > App Permissions and enable Sensors and Activity Recognition. Also ensure your device has the required sensors.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'The app is using too much battery',
                        'Try reducing the sampling rate in Settings > Recognition Settings. Lower sampling rates use less battery but may slightly reduce accuracy.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'Activity history is not saving',
                        'Check Settings > Recognition Settings and ensure "Save Activity History" is enabled. Also verify you have sufficient storage space on your device.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'Backend connection failed',
                        'If you\'re using a backend server, ensure it\'s running and accessible. For Android emulator, use 10.0.2.2 instead of localhost. Check your network connection and firewall settings.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Features & Settings',
                    Icons.settings,
                    TWColors.purple500,
                    [
                      _buildFAQItem(
                        themeProvider,
                        'What is High Accuracy Mode?',
                        'High Accuracy Mode uses more processing power for better activity detection accuracy. It may use more battery but provides more reliable results.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'How do I export my activity data?',
                        'Go to Settings > Data Management > Export Data. Your activity history will be exported as a CSV file that you can share or analyze.',
                      ),
                      _buildFAQItem(
                        themeProvider,
                        'Can I customize the confidence threshold?',
                        'Yes! Go to Settings > Recognition Settings and adjust the Confidence Threshold slider. Higher values mean more strict activity detection.',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildContactSection(context, themeProvider),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TWColors.emerald500, TWColors.teal500],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: TWColors.emerald500.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.help_outline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Need Quick Help?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  themeProvider,
                  'FAQ',
                  Icons.quiz,
                  () {
                    // Scroll to FAQ section
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildQuickActionButton(
                  context,
                  themeProvider,
                  'Contact',
                  Icons.email,
                  () {
                    // Scroll to contact section
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    ThemeProvider themeProvider,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    ThemeProvider themeProvider,
    String title,
    IconData icon,
    Color color,
    List<Widget> children,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFAQItem(ThemeProvider themeProvider, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 12),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: TWColors.blue500,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: themeProvider.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TWColors.blue500.withOpacity(0.1),
            TWColors.purple500.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: TWColors.blue500.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: TWColors.blue500.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.contact_support,
                  color: TWColors.blue500,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Contact Support',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: themeProvider.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactItem(
            themeProvider,
            Icons.email,
            'Email',
            'support@harmony.app',
            'We typically respond within 24 hours',
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            themeProvider,
            Icons.language,
            'Website',
            'www.harmony.app',
            'Visit our website for more information',
          ),
          const SizedBox(height: 16),
          _buildContactItem(
            themeProvider,
            Icons.bug_report,
            'Report a Bug',
            'bug@harmony.app',
            'Help us improve by reporting issues',
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    ThemeProvider themeProvider,
    IconData icon,
    String label,
    String value,
    String subtitle,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: themeProvider.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.textSecondary.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: TWColors.blue500.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: TWColors.blue500, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: themeProvider.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    color: TWColors.blue500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: themeProvider.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: themeProvider.textSecondary,
          ),
        ],
      ),
    );
  }
}
