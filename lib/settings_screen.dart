import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'workout_store.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmReset(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset demo data?'),
        content: const Text(
          'All your workouts will be replaced with the sample data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await WorkoutStore.instance.resetToSampleData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sample data restored')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeModeNotifier,
        builder: (context, mode, _) {
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text('Dark mode'),
                subtitle: const Text('Switch between light and dark theme'),
                value: mode == ThemeMode.dark,
                onChanged: (isDark) {
                  themeModeNotifier.value =
                      isDark ? ThemeMode.dark : ThemeMode.light;
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore),
                title: const Text('Reset demo data'),
                subtitle: const Text('Replace all workouts with sample data'),
                onTap: () => _confirmReset(context),
              ),
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
                subtitle: Text('Repify v1.1 · KTU coursework'),
              ),
            ],
          );
        },
      ),
    );
  }
}
