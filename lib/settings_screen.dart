import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'workout_store.dart';

/// Lets the user change the backend address and checks the connection.
/// Emulator: http://10.0.2.2:8000 · Real phone: http://<laptop IP>:8000
Future<void> showServerUrlDialog(BuildContext context) async {
  final controller = TextEditingController(text: ApiClient.instance.baseUrl);
  final url = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Server address'),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.url,
        decoration: const InputDecoration(
          labelText: 'Server URL',
          helperText: 'Emulator: http://10.0.2.2:8000\nPhone: http://<laptop IP>:8000',
          helperMaxLines: 3,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, ApiClient.defaultBaseUrl),
          child: const Text('Default'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, controller.text),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  if (url == null || url.trim().isEmpty) return;
  await ApiClient.instance.setBaseUrl(url);
  final ok = await ApiClient.instance.ping();
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: ok ? AppColors.cardHigh : AppColors.danger,
      content: Text(
        ok
            ? 'Connected to ${ApiClient.instance.baseUrl}'
            : 'Saved, but ${ApiClient.instance.baseUrl} is not reachable',
      ),
    ),
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _syncNow(BuildContext context) async {
    final ok = await WorkoutStore.instance.refresh();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ok ? AppColors.cardHigh : AppColors.danger,
        content: Text(
          ok ? 'Synced with the server' : WorkoutStore.instance.syncError ?? 'Sync failed',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: WorkoutStore.instance,
        builder: (context, _) {
          final store = WorkoutStore.instance;
          final pending = store.unsyncedCount;
          return ListView(
            children: [
              ListTile(
                leading: const Icon(Icons.person_outline, color: AppColors.lime),
                title: const Text('Account'),
                subtitle: Text(ApiClient.instance.email ?? 'Not logged in'),
              ),
              ListTile(
                leading: const Icon(Icons.dns_outlined, color: AppColors.lime),
                title: const Text('Server address'),
                subtitle: Text(ApiClient.instance.baseUrl),
                onTap: () => showServerUrlDialog(context),
              ),
              ListTile(
                leading: store.isSyncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync, color: AppColors.lime),
                title: const Text('Sync now'),
                subtitle: Text(
                  pending > 0
                      ? '$pending workout(s) waiting to be uploaded'
                      : store.syncError ?? 'All workouts are on the server',
                ),
                onTap: store.isSyncing ? null : () => _syncNow(context),
              ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.info_outline, color: AppColors.lime),
                title: Text('About'),
                subtitle: Text('Repify v2.0 · Flutter + Django REST · KTU coursework'),
              ),
            ],
          );
        },
      ),
    );
  }
}
