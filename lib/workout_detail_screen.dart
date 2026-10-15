import 'package:flutter/material.dart';
import 'workout_store.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Workout workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(workout.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            workout.formattedDate,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                  icon: Icons.timer_outlined,
                  label: 'Duration',
                  value: workout.hasDuration ? workout.formattedDuration : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.list_alt,
                  label: 'Exercises',
                  value: '${workout.exercises.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InfoTile(
                  icon: Icons.scale_outlined,
                  label: 'Volume',
                  value: workout.formattedVolume,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Exercises',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...workout.exercises.map(
            (ex) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(ex.name),
                subtitle: Text(
                  '${ex.sets} sets × ${ex.reps} reps · ${ex.weight} kg',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}