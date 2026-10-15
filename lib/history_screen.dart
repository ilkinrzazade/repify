import 'package:flutter/material.dart';
import 'workout_card.dart';
import 'workout_store.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkoutStore.instance,
      builder: (context, _) {
        final workouts = WorkoutStore.instance.workouts;
        if (workouts.isEmpty) {
          return const Center(child: Text('No workouts yet'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: workouts.length,
          itemBuilder: (context, index) => WorkoutCard(workout: workouts[index]),
        );
      },
    );
  }
}