import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:harmony_app/core/app_providers.dart';
import 'package:harmony_app/shared/widgets/theme_provider.dart';
import 'package:harmony_app/shared/widgets/tailwind/tw_colors.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _goalController = TextEditingController();

  bool _notificationsEnabled = true;
  bool _privacyMode = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final settings = await ref.read(activityStorageServiceProvider).getSettings();
    setState(() {
      _nameController.text = settings['userName']?.toString() ?? '';
      _ageController.text = settings['userAge']?.toString() ?? '';
      _heightController.text = settings['userHeight']?.toString() ?? '';
      _goalController.text = (settings['dailyGoalMinutes'] ?? 45).toString();
      _notificationsEnabled = settings['notificationsEnabled'] as bool? ?? true;
      _privacyMode = settings['privacyMode'] as bool? ?? false;
      _loading = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    final settings = {
      'userName': _nameController.text.trim(),
      'userAge': int.tryParse(_ageController.text.trim()) ?? 0,
      'userHeight': double.tryParse(_heightController.text.trim()) ?? 0,
      'dailyGoalMinutes': int.tryParse(_goalController.text.trim()) ?? 45,
      'notificationsEnabled': _notificationsEnabled,
      'privacyMode': _privacyMode,
    };
    await ref.read(activityStorageServiceProvider).updateSettings(settings);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    }
  }

  Future<void> _resetData() async {
    final storage = ref.read(activityStorageServiceProvider);
    await storage.clearAllSessions();
    await storage.clearSensorSnapshots();
    await storage.clearCoachAlerts();
    await storage.saveSettings({});
    await _loadProfile();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data reset')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProviderProvider);
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        title: const Text('Profile & Goals'),
        backgroundColor: theme.cardColor,
        foregroundColor: theme.textPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileCard(theme),
                const SizedBox(height: 16),
                _buildGoalCard(theme),
                const SizedBox(height: 16),
                _buildPreferencesCard(theme),
                const SizedBox(height: 16),
                _buildResetCard(theme),
              ],
            ),
    );
  }

  Widget _buildProfileCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Details', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (cm, optional)'),
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

  Widget _buildGoalCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Activity Goal', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target active minutes'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Preferences', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() => _notificationsEnabled = value);
                ref.read(activityStorageServiceProvider).updateSettings({'notificationsEnabled': value});
              },
              title: const Text('Notifications'),
              subtitle: const Text('Coach reminders and health alerts'),
            ),
            SwitchListTile(
              value: _privacyMode,
              onChanged: (value) {
                setState(() => _privacyMode = value);
                ref.read(activityStorageServiceProvider).updateSettings({'privacyMode': value});
              },
              title: const Text('Privacy Mode'),
              subtitle: const Text('Limit network calls and keep data on-device'),
            ),
            const SizedBox(height: 8),
            Text('Theme', style: TextStyle(color: theme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _themeChip('System', ThemeModeOption.system),
                _themeChip('Light', ThemeModeOption.light),
                _themeChip('Dark', ThemeModeOption.dark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip(String label, ThemeModeOption option) {
    final themeProvider = ref.watch(themeProviderProvider);
    final selected = themeProvider.themeModeOption == option;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      selectedColor: TWColors.blue500,
      labelStyle: TextStyle(color: selected ? Colors.white : themeProvider.textPrimary),
      onSelected: (_) {
        ref.read(themeModeProvider.notifier).setThemeMode(option);
        ref.read(activityStorageServiceProvider).updateSettings({'themeMode': option.name});
      },
    );
  }

  Widget _buildResetCard(ThemeProvider theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Data', style: TextStyle(color: theme.textPrimary, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Clear activity history, snapshots, and saved preferences.', style: TextStyle(color: theme.textSecondary)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset all data?'),
                    content: const Text('This will delete all locally stored activity data.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reset', style: TextStyle(color: TWColors.red500))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _resetData();
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Reset Everything'),
              style: ElevatedButton.styleFrom(backgroundColor: TWColors.red500, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
