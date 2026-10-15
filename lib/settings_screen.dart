import 'package:flutter/material.dart';
import 'app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
              const ListTile(
                leading: Icon(Icons.info_outline),
                title: Text('About'),
                subtitle: Text('Repify v1.0 · KTU coursework'),
              ),
            ],
          );
        },
      ),
    );
  }
}