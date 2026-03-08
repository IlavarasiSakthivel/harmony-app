import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart' show themeProviderProvider, ThemeProvider, themeModeProvider, ThemeModeOption;
import 'package:harmony_app/core/app_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _highAccuracy = true;
  bool _saveHistory = true;
  bool _vibrationFeedback = true;
  double _samplingRate = 50.0;
  double _confidenceThreshold = 0.7;

  bool _isExporting = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await ref.read(activityStorageServiceProvider).getSettings();
    setState(() {
      _highAccuracy = settings['highAccuracy'] ?? true;
      _saveHistory = settings['saveHistory'] ?? true;
      _vibrationFeedback = settings['vibrationFeedback'] ?? true; // Assuming default true
      _samplingRate = settings['samplingRate'] ?? 50.0;
      _confidenceThreshold = settings['confidenceThreshold'] ?? 0.7;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final activityStorageService = ref.read(activityStorageServiceProvider);
    final currentSettings = await activityStorageService.getSettings();
    currentSettings[key] = value;
    await activityStorageService.saveSettings(currentSettings);
  }

  void _showBackendUrlDialog(BuildContext context) {
    final cfg = ref.read(backendConfigProvider);
    final controller = TextEditingController(text: cfg.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'http://192.168.1.2:8000'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                ref.read(backendConfigProvider).setBaseUrl(url);
                _showSnackbar(context, 'Backend URL updated');
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = ref.watch(themeProviderProvider);

    return Scaffold(
      backgroundColor: themeProvider.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: themeProvider.cardColor,
        foregroundColor: themeProvider.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, '/about'),
            tooltip: 'About',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Appearance
            _buildSettingsCard(
              themeProvider: themeProvider,
              icon: Icons.wb_sunny,
              iconColor: TWColors.amber500,
              iconBgColor: themeProvider.isDarkMode ? TWColors.amber900 : TWColors.amber100,
              title: 'Appearance',
              children: [
                _buildSettingSwitch(
                  themeProvider: themeProvider,
                  title: 'Dark Mode',
                  subtitle: 'Switch between light and dark theme',
                  value: themeProvider.isDarkMode,
                  onChanged: (value) {
                    final newMode = value ? ThemeModeOption.dark : ThemeModeOption.light;
                    ref.read(themeModeProvider.notifier).setThemeMode(newMode);
                    _showSnackbar(context, 'Dark mode ${value ? 'enabled' : 'disabled'}');
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Recognition Settings
            _buildSettingsCard(
              themeProvider: themeProvider,
              icon: Icons.memory,
              iconColor: TWColors.emerald500,
              iconBgColor: themeProvider.isDarkMode ? TWColors.emerald900 : TWColors.emerald100,
              title: 'Recognition Settings',
              children: [
                _buildSettingSwitch(
                  themeProvider: themeProvider,
                  title: 'High Accuracy Mode',
                  subtitle: 'More accurate but uses more battery',
                  value: _highAccuracy,
                  onChanged: (value) async {
                    setState(() => _highAccuracy = value);
                    await _saveSetting('highAccuracy', value);
                    _showSnackbar(context, 'High accuracy mode ${value ? 'enabled' : 'disabled'}');
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingSwitch(
                  themeProvider: themeProvider,
                  title: 'Save Activity History',
                  subtitle: 'Store recognition history locally',
                  value: _saveHistory,
                  onChanged: (value) async {
                    setState(() => _saveHistory = value);
                    await _saveSetting('saveHistory', value);
                    _showSnackbar(context, 'History saving ${value ? 'enabled' : 'disabled'}');
                  },
                ),
                const SizedBox(height: 16),
                _buildSettingSwitch(
                  themeProvider: themeProvider,
                  title: 'Vibration Feedback',
                  subtitle: 'Vibrate on activity change',
                  value: _vibrationFeedback,
                  onChanged: (value) async {
                    setState(() => _vibrationFeedback = value);
                    await _saveSetting('vibrationFeedback', value);
                    _showSnackbar(context, 'Vibration feedback ${value ? 'enabled' : 'disabled'}');
                  },
                ),
                const SizedBox(height: 24),
                _buildSliderSetting(
                  themeProvider: themeProvider,
                  title: 'Sampling Rate',
                  value: _samplingRate,
                  min: 10,
                  max: 100,
                  divisions: 9,
                  label: 'Hz',
                  onChanged: (value) async {
                    setState(() => _samplingRate = value);
                    await _saveSetting('samplingRate', value);
                  },
                ),
                const SizedBox(height: 24),
                _buildSliderSetting(
                  themeProvider: themeProvider,
                  title: 'Confidence Threshold',
                  value: _confidenceThreshold,
                  min: 0.5,
                  max: 0.95,
                  divisions: 9,
                  label: '%',
                  isPercentage: true,
                  onChanged: (value) async {
                    setState(() => _confidenceThreshold = value);
                    await _saveSetting('confidenceThreshold', value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Backend Configuration
            _buildSettingsCard(
              themeProvider: themeProvider,
              icon: Icons.cloud,
              iconColor: TWColors.indigo500,
              iconBgColor: themeProvider.isDarkMode ? TWColors.indigo900 : TWColors.indigo100,
              title: 'Backend',
              children: [
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.settings_ethernet,
                  title: 'Configure URL',
                  subtitle: 'Current: ${ref.watch(backendConfigProvider).baseUrl}',
                  color: TWColors.indigo500,
                  onTap: () => _showBackendUrlDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 16),
            // Data Management
            _buildSettingsCard(
              themeProvider: themeProvider,
              icon: Icons.data_object,
              iconColor: TWColors.blue500,
              iconBgColor: themeProvider.isDarkMode ? TWColors.blue900 : TWColors.blue100,
              title: 'Data Management',
              children: [
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.delete,
                  title: 'Clear History',
                  subtitle: 'Delete all stored activity data',
                  color: TWColors.red500,
                  isLoading: _isClearing,
                  onTap: () => _showClearHistoryDialog(context),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.share,
                  title: 'Export Data',
                  subtitle: 'Export activity data as CSV or open Data & Export',
                  color: TWColors.emerald500,
                  isLoading: _isExporting,
                  onTap: () => _exportData(context),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.shield,
                  title: 'Privacy Dashboard',
                  subtitle: 'On-device only, view/delete data, explainable AI',
                  color: TWColors.indigo500,
                  onTap: () => Navigator.pushNamed(context, '/privacy-dashboard'),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.person,
                  title: 'Profile & Goals',
                  subtitle: 'Age, height, daily goals, badges',
                  color: TWColors.blue500,
                  onTap: () => Navigator.pushNamed(context, '/profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // About & Legal
            _buildSettingsCard(
              themeProvider: themeProvider,
              icon: Icons.info,
              iconColor: TWColors.slate500,
              iconBgColor: themeProvider.isDarkMode ? TWColors.slate800 : TWColors.slate100,
              title: 'About & Legal',
              children: [
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.description,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy practices',
                  color: TWColors.blue500,
                  onTap: () => Navigator.pushNamed(context, '/privacy'),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.security,
                  title: 'Terms of Service',
                  subtitle: 'Usage terms and conditions',
                  color: TWColors.purple500,
                  onTap: () => Navigator.pushNamed(context, '/terms'),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  color: TWColors.emerald500,
                  onTap: () => Navigator.pushNamed(context, '/help'),
                ),
                const SizedBox(height: 16),
                _buildSettingButton(
                  themeProvider: themeProvider,
                  icon: Icons.star,
                  title: 'Rate App',
                  subtitle: 'Share your feedback on store',
                  color: TWColors.amber500,
                  onTap: () => _showComingSoon(context, 'Rate App'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Text(
                    'HARmony v1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© 2025 HARmony Team',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Made with ❤️ for activity recognition',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required ThemeProvider themeProvider,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
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

  Widget _buildSettingSwitch({
    required ThemeProvider themeProvider,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: themeProvider.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: themeProvider.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: TWColors.emerald500,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSliderSetting({
    required ThemeProvider themeProvider,
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    bool isPercentage = false,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: themeProvider.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isPercentage
              ? '${(value * 100).toInt()}%'
              : '${value.toInt()} $label',
          style: TextStyle(
            fontSize: 14,
            color: themeProvider.textSecondary,
          ),
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: isPercentage
              ? '${(value * 100).toInt()}%'
              : '${value.toInt()} $label',
          activeColor: TWColors.emerald500,
          inactiveColor: themeProvider.isDarkMode ? TWColors.slate700 : TWColors.slate200,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSettingButton({
    required ThemeProvider themeProvider,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    bool isLoading = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: themeProvider.textSecondary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isLoading
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              )
                  : Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: themeProvider.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: themeProvider.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(Icons.arrow_forward_ios, color: themeProvider.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  void _showClearHistoryDialog(BuildContext context) {
    final themeProvider = ref.read(themeProviderProvider);
    final activityStorageService = ref.read(activityStorageServiceProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear History',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: themeProvider.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete all activity history? This action cannot be undone.',
          style: TextStyle(
            fontSize: 16,
            color: themeProvider.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontSize: 16,
                color: themeProvider.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isClearing = true);

              try {
                await activityStorageService.clearAllSessions();
                _showSnackbar(
                  context,
                  'History cleared successfully',
                  color: TWColors.emerald500,
                );
              } catch (e) {
                _showSnackbar(
                  context,
                  'Error clearing history: $e',
                  color: TWColors.red500,
                );
              } finally {
                setState(() => _isClearing = false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: TWColors.red500,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    setState(() => _isExporting = true);
    try {
      final activityStorageService = ref.read(activityStorageServiceProvider);
      final csvContent = await activityStorageService.exportSessionsAsCsv();
      final sessions = await activityStorageService.getAllSessions();
      if (sessions.isEmpty) {
        if (mounted) _showSnackbar(context, 'No activity data to export', color: TWColors.amber500);
        return;
      }
      final dir = await getTemporaryDirectory();
      final fileName = 'harmony_activities_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(csvContent);
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'HARmony Activity Data',
        text: 'Activity recognition export from HARmony app.',
      );
      if (mounted) _showSnackbar(context, 'Data exported successfully', color: TWColors.emerald500);
    } catch (e) {
      if (mounted) _showSnackbar(context, 'Export failed: $e', color: TWColors.red500);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showComingSoon(BuildContext context, String feature) {
    _showSnackbar(context, '$feature - Coming Soon!', color: TWColors.amber500);
  }

  void _showSnackbar(BuildContext context, String message, {Color color = TWColors.blue500}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
