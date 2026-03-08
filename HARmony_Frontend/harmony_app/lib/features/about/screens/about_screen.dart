import 'package:flutter/material.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, ThemeProvider;

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeProviderProvider);
    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: themeProvider.cardColor,
        foregroundColor: themeProvider.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeProvider.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // App Logo & Info
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TWColors.teal500,
                      TWColors.emerald500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.directions_walk, size: 40, color: TWColors.teal600),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'HARmony',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Human Activity Recognition System',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Description
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About HARmony',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'HARmony is an advanced Human Activity Recognition system that uses machine learning and device sensors to detect and classify human activities in real-time.',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'The app utilizes TensorFlow Lite for on-device inference, ensuring privacy and low latency. It can recognize activities like walking, running, standing, sitting, and more.',
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.textSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Features
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Key Features',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.memory,
                      title: 'On-device AI',
                      description: 'TensorFlow Lite model runs locally',
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.directions_walk,
                      title: 'Real-time Detection',
                      description: 'Instant activity recognition',
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.security,
                      title: 'Privacy First',
                      description: 'No data leaves your device',
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.battery_charging_full,
                      title: 'Power Efficient',
                      description: 'Optimized for battery life',
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Team
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: themeProvider.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(themeProvider.isDarkMode ? 0.3 : 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Development Team',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: themeProvider.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _TeamMember(
                      name: 'Ilavarasi Sakthivel',
                      role: 'Developer',
                      avatarColor: TWColors.teal500,
                      themeProvider: themeProvider,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Footer
              Column(
                children: [
                  Text(
                    '© 2025 HARmony Project. All rights reserved.',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Started in 2025',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for the research community',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final ThemeProvider themeProvider;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? TWColors.teal900 : TWColors.teal50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: TWColors.teal600, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TeamMember extends StatelessWidget {
  final String name;
  final String role;
  final Color avatarColor;
  final ThemeProvider themeProvider;

  const _TeamMember({
    required this.name,
    required this.role,
    required this.avatarColor,
    required this.themeProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: themeProvider.isDarkMode ? avatarColor.withOpacity(0.2) : avatarColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              name.substring(0, 1),
              style: TextStyle(
                fontSize: 20,
                color: themeProvider.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
