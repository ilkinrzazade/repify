import 'package:flutter/material.dart';
import 'workout_store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.deepPurple,
              child: Icon(Icons.person, size: 56, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ilkin Rzazade',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Text(
            'ilkin@example.com',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ListenableBuilder(
            listenable: WorkoutStore.instance,
            builder: (context, _) {
              final workouts = WorkoutStore.instance.workouts;
              final exercises = workouts.fold<int>(
                0,
                (sum, w) => sum + w.exercises.length,
              );
              return Row(
                children: [
                  Expanded(child: _StatCard(label: 'Workouts', value: '${workouts.length}')),
                  const SizedBox(width: 12),
                  Expanded(child: _StatCard(label: 'Exercises', value: '$exercises')),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}