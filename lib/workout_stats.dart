import 'workout_store.dart';

/// Pure helper functions for statistics.
/// They have no UI and no storage, so they are easy to unit test.

const List<String> monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// "Nov 24"
String shortDate(DateTime date) => '${monthNames[date.month - 1]} ${date.day}';

/// 80.0 -> "80", 77.5 -> "77.5"
String formatKg(double value) => value == value.roundToDouble()
    ? value.toStringAsFixed(0)
    : value.toStringAsFixed(1);

/// "Bench Press " and "bench press" are treated as the same exercise.
String normalizeExerciseName(String name) => name.trim().toLowerCase();

/// Heaviest weight ever lifted for each exercise (keys are normalized names).
Map<String, double> personalRecords(Iterable<Workout> workouts) {
  final records = <String, double>{};
  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final key = normalizeExerciseName(exercise.name);
      if (key.isEmpty) continue;
      final best = records[key];
      if (best == null || exercise.weightKg > best) {
        records[key] = exercise.weightKg;
      }
    }
  }
  return records;
}

/// Exercises in [workout] that beat the previous best weight.
/// A brand-new exercise (no history yet) is not counted as a record.
List<String> newPersonalRecords(Iterable<Workout> previous, Workout workout) {
  final records = personalRecords(previous);
  final result = <String>[];
  final seen = <String>{};
  for (final exercise in workout.exercises) {
    final key = normalizeExerciseName(exercise.name);
    final best = records[key];
    if (best != null && exercise.weightKg > best && seen.add(key)) {
      result.add(exercise.name.trim());
    }
  }
  return result;
}

/// True when this exercise matches the all-time best weight.
bool isPersonalRecord(Map<String, double> records, Exercise exercise) {
  final best = records[normalizeExerciseName(exercise.name)];
  return best != null && exercise.weightKg > 0 && exercise.weightKg >= best;
}

class ProgressPoint {
  final DateTime date;
  final double weight;

  const ProgressPoint(this.date, this.weight);
}

/// Best weight of [exercise] in each workout, oldest first.
List<ProgressPoint> progressFor(Iterable<Workout> workouts, String exercise) {
  final key = normalizeExerciseName(exercise);
  final points = <ProgressPoint>[];
  for (final workout in workouts) {
    double? best;
    for (final e in workout.exercises) {
      if (normalizeExerciseName(e.name) != key) continue;
      if (best == null || e.weightKg > best) best = e.weightKg;
    }
    if (best != null && best > 0) points.add(ProgressPoint(workout.date, best));
  }
  points.sort((a, b) => a.date.compareTo(b.date));
  return points;
}

/// Exercise names the user has logged, most frequent first.
List<String> trackedExercises(Iterable<Workout> workouts) {
  final counts = <String, int>{};
  final displayNames = <String, String>{};
  for (final workout in workouts) {
    for (final e in workout.exercises) {
      final key = normalizeExerciseName(e.name);
      if (key.isEmpty) continue;
      counts[key] = (counts[key] ?? 0) + 1;
      displayNames.putIfAbsent(key, () => e.name.trim());
    }
  }
  final keys = counts.keys.toList()
    ..sort((a, b) {
      final byCount = counts[b]!.compareTo(counts[a]!);
      return byCount != 0 ? byCount : a.compareTo(b);
    });
  return keys.map((k) => displayNames[k]!).toList();
}
