import 'exercise_catalog.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

/// "Smart Coach": simple, explainable training rules.

// ---------- Progressive overload ----------

class WeightSuggestion {
  final double weight;
  final int reps;
  final String reason;

  const WeightSuggestion(this.weight, this.reps, this.reason);
}

/// Big compound lifts go up in 5 kg steps, everything else in 2.5 kg steps.
const Set<String> _heavyLifts = {'squat', 'deadlift', 'leg press', 'romanian deadlift'};

double weightStepFor(String exercise) =>
    _heavyLifts.contains(normalizeExerciseName(exercise)) ? 5.0 : 2.5;

/// Progressive overload rule:
/// - 8 or more reps last time -> add weight, keep the reps.
/// - fewer than 8 reps -> keep the weight and aim for one more rep.
WeightSuggestion? suggestNext(Exercise? last) {
  if (last == null || last.weightKg <= 0) return null;
  final reps = int.tryParse(last.reps) ?? 0;
  if (reps <= 0) return null;

  if (reps >= 8) {
    final step = weightStepFor(last.name);
    return WeightSuggestion(
      last.weightKg + step,
      reps,
      'You did $reps reps at ${formatKg(last.weightKg)} kg last time. '
      'Add ${formatKg(step)} kg.',
    );
  }
  return WeightSuggestion(
    last.weightKg,
    reps + 1,
    'Keep ${formatKg(last.weightKg)} kg and aim for ${reps + 1} reps.',
  );
}

// ---------- Muscle recovery ----------

/// Muscles need about 48 hours to recover after strength training.
const int recoveryDays = 2;

class MuscleStatus {
  final String group;

  /// Days since this group was last trained, or null if never.
  final int? daysSince;

  const MuscleStatus(this.group, this.daysSince);

  bool get trained => daysSince != null;
  bool get ready => daysSince == null || daysSince! >= recoveryDays;

  String get label {
    if (daysSince == null) return 'never';
    if (daysSince == 0) return 'today';
    if (daysSince == 1) return '1 day ago';
    return '$daysSince days ago';
  }
}

int _calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// For each muscle group: how many days ago it was last trained.
List<MuscleStatus> muscleRecovery(Iterable<Workout> workouts, {DateTime? now}) {
  final today = now ?? DateTime.now();
  final lastTrained = <String, DateTime>{};
  for (final workout in workouts) {
    for (final exercise in workout.exercises) {
      final group = muscleGroupOf(exercise.name);
      if (group == null) continue;
      final previous = lastTrained[group];
      if (previous == null || workout.date.isAfter(previous)) {
        lastTrained[group] = workout.date;
      }
    }
  }
  return exerciseCatalog.keys.map((group) {
    final date = lastTrained[group];
    if (date == null) return MuscleStatus(group, null);
    final days = _calendarDaysBetween(date, today);
    return MuscleStatus(group, days < 0 ? 0 : days);
  }).toList();
}

/// The recovered muscle group that has rested the longest.
/// Groups trained before come first; never-trained groups are the fallback.
/// Returns null when everything is still recovering (rest day).
String? suggestedFocus(List<MuscleStatus> statuses) {
  MuscleStatus? best;
  for (final s in statuses) {
    if (!s.trained || !s.ready) continue;
    if (best == null || s.daysSince! > best.daysSince!) best = s;
  }
  if (best != null) return best.group;
  for (final s in statuses) {
    if (!s.trained) return s.group;
  }
  return null;
}
