import 'package:flutter/material.dart';

import 'workout_card.dart';
import 'workout_store.dart';

/// All saved workouts. Swipe a card to the left to delete it (with Undo).
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _onDeleted(BuildContext context, Workout workout) {
    final messenger = ScaffoldMessenger.of(context);
    WorkoutStore.instance.removeWorkout(workout.id);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${workout.name}" deleted'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => WorkoutStore.instance.restoreWorkout(workout),
          ),
        ),
      );
  }

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
          itemCount: workouts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text(
                  'Swipe left on a workout to delete it.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              );
            }
            final workout = workouts[index - 1];
            return Dismissible(
              key: ValueKey(workout.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: Colors.red.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) => _onDeleted(context, workout),
              child: WorkoutCard(workout: workout),
            );
          },
        );
      },
    );
  }
}
