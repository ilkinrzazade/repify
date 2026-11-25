import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/exercise_catalog.dart';
import 'package:my_app/workout_store.dart';

void main() {
  group('Exercise catalog', () {
    test('finds the muscle group of a catalog exercise', () {
      expect(muscleGroupOf('bench press'), 'Chest');
      expect(muscleGroupOf('Squat'), 'Legs');
      expect(muscleGroupOf('My Custom Move'), isNull);
    });

    test('suggests a workout name from the main muscle group', () {
      expect(
        suggestedWorkoutName(['Bench Press', 'Chest Fly', 'Triceps Pushdown']),
        'Chest Day',
      );
      expect(suggestedWorkoutName(['Squat', 'Leg Press']), 'Leg Day');
      expect(suggestedWorkoutName([]), 'Workout');
      expect(suggestedWorkoutName(['My Custom Move']), 'Workout');
    });

    test('remembers the most recent values of an exercise', () {
      final workouts = [
        Workout(
          name: 'Old',
          date: DateTime(2026, 11, 1),
          exercises: const [
            Exercise(name: 'Bench Press', sets: '3', reps: '10', weight: '80'),
          ],
        ),
        Workout(
          name: 'New',
          date: DateTime(2026, 11, 10),
          exercises: const [
            Exercise(name: 'Bench Press', sets: '4', reps: '8', weight: '85'),
          ],
        ),
      ];
      final last = lastExerciseFor(workouts, 'bench press');
      expect(last?.weightKg, 85);
      expect(last?.sets, '4');
      expect(lastExerciseFor(workouts, 'Squat'), isNull);
    });
  });
}
