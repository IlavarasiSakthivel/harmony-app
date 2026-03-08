import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum ThemeModeOption {
  system,
  light,
  dark,
}

class ThemeModeNotifier extends Notifier<ThemeModeOption> {
  @override
  ThemeModeOption build() {
    _loadThemeMode();
    return ThemeModeOption.dark;
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('app_settings');
      if (raw != null) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final mode = map['themeMode']?.toString();
        if (mode == ThemeModeOption.light.name) {
          state = ThemeModeOption.light;
        } else if (mode == ThemeModeOption.system.name) {
          state = ThemeModeOption.system;
        } else if (mode == ThemeModeOption.dark.name) {
          state = ThemeModeOption.dark;
        }
      }
    } catch (_) {
      // ignore read errors, fallback to default
    }
  }

  Future<void> setThemeMode(ThemeModeOption option) async {
    state = option;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('app_settings');
      final map = raw != null ? jsonDecode(raw) as Map<String, dynamic> : <String, dynamic>{};
      map['themeMode'] = option.name;
      await prefs.setString('app_settings', jsonEncode(map));
    } catch (_) {
      // ignore save errors
    }
  }

  void toggleDarkMode() {
    if (state == ThemeModeOption.dark) {
      setThemeMode(ThemeModeOption.light);
    } else {
      setThemeMode(ThemeModeOption.dark);
    }
  }
}

// Create the provider using NotifierProvider
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeModeOption>(() {
  return ThemeModeNotifier();
});

class ThemeProvider {
  final ThemeModeOption themeModeOption;

  ThemeProvider({required this.themeModeOption});

  bool get isDarkMode {
    if (themeModeOption == ThemeModeOption.dark) {
      return true;
    } else if (themeModeOption == ThemeModeOption.light) {
      return false;
    } else {
      // System theme - check current brightness
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }

  // Colors based on theme
  Color get backgroundColor => isDarkMode ? TWColors.slate900 : TWColors.slate50;
  Color get cardColor => isDarkMode ? TWColors.slate800 : Colors.white;
  Color get textPrimary => isDarkMode ? TWColors.slate50 : TWColors.slate900;
  Color get textSecondary => isDarkMode ? TWColors.slate400 : TWColors.slate600;
  Color get accentColor => TWColors.blue500;
  List<Color> get appBarGradient => isDarkMode
      ? [TWColors.slate800, TWColors.slate700]
      : [TWColors.blue50, TWColors.blue100];
}

final themeProviderProvider = Provider<ThemeProvider>((ref) {
  final themeMode = ref.watch(themeModeProvider);
  return ThemeProvider(themeModeOption: themeMode);
});
