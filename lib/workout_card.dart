import 'package:flutter/material.dart';
import 'workout_detail_screen.dart';
import 'workout_store.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;

  const WorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        isThreeLine: workout.hasDuration,
        leading: const CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
        ),
        title: Text(workout.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${workout.formattedDate} · ${workout.exercises.length} exercises',
            ),
            if (workout.hasDuration)
              Text('${workout.formattedDuration} · ${workout.formattedVolume}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkoutDetailScreen(workout: workout),
            ),
          );
        },
      ),
    );
  }
}