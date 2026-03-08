import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider;

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

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
                'Terms of Service',
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
                        ? [TWColors.purple900, TWColors.pink900]
                        : [TWColors.purple100, TWColors.pink100],
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
                          color: TWColors.purple500.withOpacity(0.1),
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
                          color: TWColors.pink500.withOpacity(0.1),
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
                    'Last Updated: January 24, 2025',
                    'Agreement to Terms',
                    'By downloading, installing, or using HARmony ("the App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Use License',
                    'License',
                    'Permission is granted to temporarily download one copy of HARmony for personal, non-commercial use only. This is the grant of a license, not a transfer of title, and under this license you may not:\n\n'
                    '• Modify or copy the materials\n'
                    '• Use the materials for any commercial purpose\n'
                    '• Attempt to reverse engineer any software contained in the App\n'
                    '• Remove any copyright or other proprietary notations from the materials\n\n'
                    'This license shall automatically terminate if you violate any of these restrictions.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Disclaimer',
                    'Limitations',
                    'The materials in HARmony are provided on an "as is" basis. We make no warranties, expressed or implied, and hereby disclaim and negate all other warranties including, without limitation:\n\n'
                    '• Implied warranties of merchantability\n'
                    '• Fitness for a particular purpose\n'
                    '• Non-infringement of intellectual property\n\n'
                    'We do not warrant or make any representations concerning the accuracy, likely results, or reliability of the use of the materials in the App.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Accuracy of Materials',
                    'Materials',
                    'The materials appearing in HARmony could include technical, typographical, or photographic errors. We do not warrant that any of the materials are accurate, complete, or current. We may make changes to the materials at any time without notice.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Limitations',
                    'Liability',
                    'In no event shall HARmony or its suppliers be liable for any damages (including, without limitation, damages for loss of data or profit, or due to business interruption) arising out of the use or inability to use the App, even if we have been notified orally or in writing of the possibility of such damage.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Revisions',
                    'Updates',
                    'We may revise these Terms of Service at any time without notice. By using the App, you are agreeing to be bound by the then current version of these Terms of Service.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Governing Law',
                    'Law',
                    'These Terms and Conditions are governed by and construed in accordance with applicable laws. Any disputes relating to these Terms shall be subject to the exclusive jurisdiction of the courts in the jurisdiction where the App is provided.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'User Responsibilities',
                    'Responsibilities',
                    'As a user of HARmony, you agree to:\n\n'
                    '• Use the App only for lawful purposes\n'
                    '• Not interfere with or disrupt the App\'s functionality\n'
                    '• Not attempt to gain unauthorized access to any part of the App\n'
                    '• Provide accurate information when required\n'
                    '• Maintain the security of your device\n\n'
                    'Violation of these responsibilities may result in termination of your access to the App.',
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    context,
                    themeProvider,
                    'Contact Information',
                    'Contact',
                    'If you have any questions about these Terms of Service, please contact us:\n\n'
                    'Email: legal@harmony.app\n'
                    'Website: www.harmony.app\n\n'
                    'We will respond to your inquiries as soon as possible.',
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
                  color: TWColors.purple500.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description,
                  color: TWColors.purple500,
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
                        color: TWColors.purple500,
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

  Widget _buildAcceptButton(BuildContext context, ThemeProvider themeProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [TWColors.purple500, TWColors.pink500],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: TWColors.purple500.withOpacity(0.3),
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
          'I Agree',
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
