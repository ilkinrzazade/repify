import 'package:flutter/material.dart';

import 'api_client.dart';
import 'app_theme.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final email = ApiClient.instance.email ?? '';
    final name = email.isEmpty ? 'Repify user' : email.split('@').first;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListenableBuilder(
        listenable: WorkoutStore.instance,
        builder: (context, _) {
          final workouts = WorkoutStore.instance.workouts;
          final exercises = workouts.fold<int>(0, (sum, w) => sum + w.exercises.length);
          final volume = workouts.fold<double>(0, (sum, w) => sum + w.totalVolume);
          final records = personalRecords(workouts).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.lime,
                  ),
                  child: const CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.card,
                    child: Icon(Icons.person, size: 54, color: AppColors.lime),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.6,
                children: [
                  _StatCard(icon: Icons.fitness_center, value: '${workouts.length}', label: 'Workouts'),
                  _StatCard(icon: Icons.list_alt, value: '$exercises', label: 'Exercises logged'),
                  _StatCard(icon: Icons.bolt, value: compactNumber(volume), label: 'kg lifted'),
                  _StatCard(icon: Icons.emoji_events, value: '$records', label: 'Personal records'),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconBadge(icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Text(
                  label,
                  maxLines: 2,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
