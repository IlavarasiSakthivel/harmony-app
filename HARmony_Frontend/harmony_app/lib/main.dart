import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/theme/app_themes.dart';
import 'package:harmony_app/features/about/screens/about_screen.dart';
import 'package:harmony_app/features/activity_recognition/screens/history_screen.dart';
import 'package:harmony_app/features/activity_recognition/screens/realtime_screen.dart';
import 'package:harmony_app/features/analytics/screens/analytics_screen.dart';
import 'package:harmony_app/features/coach/screens/coach_screen.dart';
import 'package:harmony_app/features/data/screens/data_history_screen.dart';
import 'package:harmony_app/features/diagnostic/screens/diagnostic_screen.dart';
import 'package:harmony_app/features/futuristic/screens/futuristic_screen.dart';
import 'package:harmony_app/features/health/screens/health_dashboard_screen.dart';
import 'package:harmony_app/features/home/screens/home_screen.dart';
import 'package:harmony_app/features/legal/screens/privacy_policy_screen.dart';
import 'package:harmony_app/features/legal/screens/terms_of_service_screen.dart';
import 'package:harmony_app/features/profile/screens/profile_screen.dart';
import 'package:harmony_app/features/settings/screens/privacy_dashboard_screen.dart';
import 'package:harmony_app/features/settings/screens/settings_screen.dart';
import 'package:harmony_app/features/support/screens/help_support_screen.dart';
import 'package:harmony_app/features/timeline/screens/timeline_screen.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeModeProvider, ThemeModeOption;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: HARmonyApp()));
}

class HARmonyApp extends ConsumerWidget {
  const HARmonyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'HARmony - Activity Recognition',
      debugShowCheckedModeBanner: false,
      
      // Using modern Material 3 themes
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: _getThemeMode(themeMode),
      
      home: const HomeScreen(),

      routes: {
        '/home': (context) => const HomeScreen(),
        '/realtime': (context) => const RealtimeRecognitionScreen(),
        '/history': (context) => const HistoryScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/coach': (context) => const CoachScreen(),
        '/health': (context) => const HealthDashboardScreen(),
        '/timeline': (context) => const TimelineScreen(),
        '/diagnostic': (context) => const DiagnosticScreen(),
        '/futuristic': (context) => const FuturisticScreen(),
        '/data': (context) => const DataHistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/privacy': (context) => const PrivacyDashboardScreen(),
        '/about': (context) => const AboutScreen(),
        '/help': (context) => const HelpSupportScreen(),
        '/terms': (context) => const TermsOfServiceScreen(),
        '/privacy-policy': (context) => const PrivacyPolicyScreen(),
      },
    );
  }

  static ThemeMode _getThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      case ThemeModeOption.system:
        return ThemeMode.system;
    }
  }
}
