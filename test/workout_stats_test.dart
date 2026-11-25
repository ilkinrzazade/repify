import 'package:flutter_test/flutter_test.dart';
import 'package:my_app/workout_stats.dart';
import 'package:my_app/workout_store.dart';

Workout workoutWith(
  List<Exercise> exercises, {
  DateTime? date,
  Duration duration = Duration.zero,
}) {
  return Workout(
    name: 'Test',
    date: date ?? DateTime(2026, 11, 1),
    exercises: exercises,
    duration: duration,
  );
}

Exercise bench(String weight) =>
    Exercise(name: 'Bench Press', sets: '4', reps: '8', weight: weight);

void main() {
  group('Exercise', () {
    test('volume is sets x reps x weight', () {
      const e = Exercise(name: 'Bench Press', sets: '3', reps: '10', weight: '60');
      expect(e.volume, 1800);
    });

    test('accepts a comma as decimal separator', () {
      expect(bench('77,5').weightKg, 77.5);
      expect(bench('77,5').volume, 4 * 8 * 77.5);
    });

    test('invalid numbers count as zero', () {
      const e = Exercise(name: 'Plank', sets: 'abc', reps: '10', weight: '');
      expect(e.volume, 0);
    });
  });

  group('Workout', () {
    test('total and formatted volume', () {
      final w = workoutWith([
        const Exercise(name: 'A', sets: '3', reps: '10', weight: '60'),
        const Exercise(name: 'B', sets: '1', reps: '10', weight: '20'),
      ]);
      expect(w.totalVolume, 2000);
      expect(w.formattedVolume, '2,000 kg');
    });

    test('formatted duration', () {
      expect(workoutWith([], duration: const Duration(seconds: 45)).formattedDuration, '45 sec');
      expect(workoutWith([], duration: const Duration(minutes: 55)).formattedDuration, '55 min');
      expect(workoutWith([], duration: const Duration(minutes: 62)).formattedDuration, '1 h 02 min');
    });

    test('formatted date', () {
      expect(workoutWith([], date: DateTime(2026, 9, 20)).formattedDate, 'Sep 20, 2026');
    });

    test('save and load (JSON) keeps all data', () {
      final original = workoutWith(
        [bench('82.5')],
        date: DateTime(2026, 11, 20, 18, 30),
        duration: const Duration(minutes: 47),
      );
      final restored = decodeWorkouts(encodeWorkouts([original])).single;
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.date, original.date);
      expect(restored.duration, original.duration);
      expect(restored.exercises.single.weightKg, 82.5);
    });
  });

  group('Personal records', () {
    test('the heaviest weight is the record (name is case-insensitive)', () {
      final records = personalRecords([
        workoutWith([bench('80')]),
        workoutWith([
          const Exercise(name: 'bench press ', sets: '1', reps: '1', weight: '90'),
        ]),
      ]);
      expect(records['bench press'], 90);
    });

    test('a heavier lift is reported as a new record', () {
      final history = [workoutWith([bench('80')])];
      expect(newPersonalRecords(history, workoutWith([bench('85')])), ['Bench Press']);
    });

    test('the same weight is not a new record', () {
      final history = [workoutWith([bench('80')])];
      expect(newPersonalRecords(history, workoutWith([bench('80')])), isEmpty);
    });

    test('a brand-new exercise is not a record', () {
      final history = [workoutWith([bench('80')])];
      final curl = workoutWith([
        const Exercise(name: 'Biceps Curl', sets: '3', reps: '10', weight: '15'),
      ]);
      expect(newPersonalRecords(history, curl), isEmpty);
    });
  });

  group('Progress', () {
    test('points are sorted oldest first and use the best set', () {
      final points = progressFor([
        workoutWith([bench('85')], date: DateTime(2026, 11, 10)),
        workoutWith([bench('70'), bench('75')], date: DateTime(2026, 11, 3)),
      ], 'Bench Press');
      expect(points.map((p) => p.weight), [75, 85]);
    });

    test('most frequent exercises come first', () {
      final names = trackedExercises([
        workoutWith([bench('80')]),
        workoutWith([
          bench('82'),
          const Exercise(name: 'Squat', sets: '4', reps: '8', weight: '100'),
        ]),
      ]);
      expect(names.first, 'Bench Press');
      expect(names, contains('Squat'));
    });

    test('sample data is not empty and newest first', () {
      final samples = sampleWorkouts();
      expect(samples, isNotEmpty);
      for (var i = 1; i < samples.length; i++) {
        expect(samples[i - 1].date.isAfter(samples[i].date), isTrue);
      }
      expect(progressFor(samples, 'Bench Press').length, 6);
    });
  });
}
