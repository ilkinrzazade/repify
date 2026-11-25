import 'workout_stats.dart';
import 'workout_store.dart';

/// Built-in list of common gym exercises, grouped by muscle group.
const Map<String, List<String>> exerciseCatalog = {
  'Chest': [
    'Bench Press',
    'Incline Bench Press',
    'Dumbbell Bench Press',
    'Chest Fly',
    'Cable Crossover',
    'Push-up',
    'Dips',
  ],
  'Back': [
    'Deadlift',
    'Pull-up',
    'Lat Pulldown',
    'Barbell Row',
    'Seated Cable Row',
    'Dumbbell Row',
  ],
  'Legs': [
    'Squat',
    'Leg Press',
    'Lunges',
    'Romanian Deadlift',
    'Leg Extension',
    'Leg Curl',
    'Calf Raise',
  ],
  'Shoulders': [
    'Overhead Press',
    'Dumbbell Shoulder Press',
    'Lateral Raise',
    'Rear Delt Fly',
    'Face Pull',
  ],
  'Arms': [
    'Biceps Curl',
    'Hammer Curl',
    'Preacher Curl',
    'Triceps Pushdown',
    'Skull Crusher',
  ],
  'Core': [
    'Plank',
    'Crunch',
    'Hanging Leg Raise',
    'Russian Twist',
  ],
};

/// Quick-pick names for a workout.
const List<String> presetWorkoutNames = [
  'Push Day',
  'Pull Day',
  'Leg Day',
  'Upper Body',
  'Full Body',
];

const Map<String, String> _dayNames = {
  'Chest': 'Chest Day',
  'Back': 'Back Day',
  'Legs': 'Leg Day',
  'Shoulders': 'Shoulder Day',
  'Arms': 'Arm Day',
  'Core': 'Core Day',
};

/// Muscle group of a catalog exercise, or null for a custom exercise.
String? muscleGroupOf(String exercise) {
  final key = normalizeExerciseName(exercise);
  for (final entry in exerciseCatalog.entries) {
    if (entry.value.any((name) => normalizeExerciseName(name) == key)) {
      return entry.key;
    }
  }
  return null;
}

/// Automatic workout name based on the most trained muscle group,
/// e.g. Bench Press + Chest Fly -> "Chest Day".
String suggestedWorkoutName(Iterable<String> exerciseNames) {
  final counts = <String, int>{};
  for (final name in exerciseNames) {
    final group = muscleGroupOf(name);
    if (group != null) counts[group] = (counts[group] ?? 0) + 1;
  }
  String? best;
  var bestCount = 0;
  for (final group in exerciseCatalog.keys) {
    final count = counts[group] ?? 0;
    if (count > bestCount) {
      best = group;
      bestCount = count;
    }
  }
  return best == null ? 'Workout' : _dayNames[best]!;
}

/// The most recent time the user did [exercise] (heaviest set of that workout).
Exercise? lastExerciseFor(Iterable<Workout> workouts, String exercise) {
  final key = normalizeExerciseName(exercise);
  final newestFirst = workouts.toList()..sort((a, b) => b.date.compareTo(a.date));
  for (final workout in newestFirst) {
    Exercise? best;
    for (final e in workout.exercises) {
      if (normalizeExerciseName(e.name) != key) continue;
      if (best == null || e.weightKg > best.weightKg) best = e;
    }
    if (best != null) return best;
  }
  return null;
}
