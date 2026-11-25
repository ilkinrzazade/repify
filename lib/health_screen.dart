import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'health_cards.dart';
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

  String _bpm(double? value) => value == null ? '–' : '${value.round()}';

  @override
  Widget build(BuildContext context) {
    final time = updated == null
        ? null
        : '${updated!.hour}:${updated!.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.today, color: AppColors.lime, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Today',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              if (time != null) ...[
                const Icon(Icons.sync, color: AppColors.muted, size: 14),
                const SizedBox(width: 4),
                Text('Updated $time', style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.45,
            children: [
              _MetricTile(
                icon: Icons.directions_walk,
                color: AppColors.lime,
                value: '${health.steps}',
                unit: 'steps',
                label: 'Goal $stepGoal',
                progress: ringProgress(health.steps, stepGoal),
              ),
              _MetricTile(
                icon: Icons.local_fire_department,
                color: calorieColor,
                value: '${health.activeCalories.round()}',
                unit: 'kcal',
                label: 'Active calories',
                progress: ringProgress(health.activeCalories, calorieGoal),
              ),
              _MetricTile(
                icon: Icons.favorite,
                color: heartColor,
                value: _bpm(health.latestBpm),
                unit: 'bpm',
                label: 'Latest heart rate',
              ),
              _MetricTile(
                icon: Icons.monitor_heart_outlined,
                color: trainingColor,
                value: _bpm(health.averageBpm),
                unit: 'bpm',
                label: '${health.heartRate.length} samples · avg',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String unit;
  final String label;
  final double? progress;

  const _MetricTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withAlpha(40),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const Spacer(),
              if (progress != null)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3,
                    color: color,
                    backgroundColor: color.withAlpha(40),
                  ),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted, fontSize: 11),
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
