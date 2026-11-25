import 'package:flutter/material.dart';

import 'app_theme.dart';
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
          return const Center(
            child: Text('No workouts yet', style: TextStyle(color: AppColors.muted)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: workouts.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '${workouts.length} workouts · swipe left to delete',
                  style: const TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              );
            }
            final workout = workouts[index - 1];
            return Dismissible(
              key: ValueKey(workout.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 22),
                alignment: Alignment.centerRight,
                decoration: BoxDecoration(
                  color: AppColors.danger,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline, color: Colors.white),
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
