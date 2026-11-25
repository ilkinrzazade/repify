import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'health_service.dart';

/// Health Connect settings: connect, refresh, demo data, privacy.
class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  void _snack(BuildContext context, String text, {bool ok = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: ok ? AppColors.lime : AppColors.danger,
      content: Text(
        text,
        style: TextStyle(color: ok ? AppColors.onLime : Colors.white, fontWeight: FontWeight.w700),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final service = HealthService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Health Connect')),
      body: ListenableBuilder(
        listenable: service,
        builder: (context, _) {
          final status = service.status;
          final (String title, String subtitle, Color color, IconData icon) = switch (status) {
            HealthStatus.connected => (
                'Connected',
                'Repify reads your daily activity and saves your workouts.',
                AppColors.lime,
                Icons.check_circle,
              ),
            HealthStatus.disconnected => (
                'Not connected',
                'Allow access to show steps, heart rate and calories.',
                AppColors.warning,
                Icons.link_off,
              ),
            HealthStatus.needsUpdate => (
                'Update needed',
                'Install or update the Health Connect app from Google Play.',
                AppColors.warning,
                Icons.system_update,
              ),
            HealthStatus.unavailable => (
                'Not available',
                'Health Connect is not supported on this device.',
                AppColors.danger,
                Icons.block,
              ),
            HealthStatus.unknown => (
                'Checking...',
                'Looking for Health Connect on this phone.',
                AppColors.muted,
                Icons.hourglass_empty,
              ),
          };

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withAlpha(22),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: color.withAlpha(120)),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 34),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 4),
                          Text(subtitle, style: const TextStyle(color: AppColors.text)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (service.error != null) ...[
                const SizedBox(height: 12),
                Text(service.error!, style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 20),
              if (status == HealthStatus.disconnected || status == HealthStatus.needsUpdate)
                ElevatedButton.icon(
                  onPressed: () async {
                    final ok = await service.connect();
                    if (context.mounted && ok) _snack(context, 'Health Connect connected');
                  },
                  icon: const Icon(Icons.favorite),
                  label: Text(status == HealthStatus.needsUpdate
                      ? 'Install Health Connect'
                      : 'Connect Health Connect'),
                ),
              if (status == HealthStatus.connected) ...[
                ElevatedButton.icon(
                  onPressed: service.isLoading ? null : service.refresh,
                  icon: const Icon(Icons.sync),
                  label: const Text('Refresh today\'s data'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await service.addDemoData();
                    if (context.mounted) {
                      _snack(
                        context,
                        ok ? 'Demo data added for today' : 'Could not add demo data',
                        ok: ok,
                      );
                    }
                  },
                  icon: const Icon(Icons.science_outlined),
                  label: const Text('Add demo data (emulator)'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: service.disconnect,
                  child: const Text('Disconnect', style: TextStyle(color: AppColors.danger)),
                ),
                const SizedBox(height: 10),
                _TodaySummary(health: service.today, updated: service.lastUpdated),
              ],
              const SizedBox(height: 20),
              const Text(
                'What Repify uses',
                style: TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const _UsageTile(Icons.directions_walk, 'Steps', 'Read · daily step ring'),
              const _UsageTile(Icons.favorite_border, 'Heart rate', 'Read · from your watch'),
              const _UsageTile(Icons.local_fire_department, 'Active calories', 'Read · daily calorie ring'),
              const _UsageTile(Icons.fitness_center, 'Workouts', 'Write · finished workouts are saved'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lock_outline, color: AppColors.lime),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Health data stays on your phone. Only today\'s totals are sent '
                        'to the AI Coach when you ask it something. You can remove access '
                        'any time in Android Settings → Health Connect.',
                        style: TextStyle(color: AppColors.muted, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final DailyHealth health;
  final DateTime? updated;

  const _TodaySummary({required this.health, this.updated});

  @override
  Widget build(BuildContext context) {
    final rows = <(String, String)>[
      ('Steps', '${health.steps}'),
      ('Active calories', '${health.activeCalories.round()} kcal'),
      ('Heart rate samples', '${health.heartRate.length}'),
      if (health.latestBpm != null) ('Latest heart rate', '${health.latestBpm!.round()} bpm'),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            updated == null
                ? 'Today'
                : 'Today · updated ${updated!.hour}:${updated!.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(child: Text(label, style: const TextStyle(color: AppColors.muted))),
                  Text(value, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _UsageTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _UsageTile(this.icon, this.title, this.subtitle);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconBadge(icon, size: 40),
      title: Text(title, style: const TextStyle(color: AppColors.text)),
      subtitle: Text(subtitle, style: const TextStyle(color: AppColors.muted)),
    );
  }
}
