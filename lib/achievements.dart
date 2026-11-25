import 'package:flutter/material.dart';

import 'workout_stats.dart';
import 'workout_store.dart';

/// Pure statistics for the Progress screen: period overviews, streaks
/// and achievement badges. No UI state here, so it is easy to unit test.

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the week that contains [d].
DateTime mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));

class PeriodBucket {
  final String label;
  final double volume;
  final int minutes;
  final int workouts;

  const PeriodBucket(this.label, this.volume, this.minutes, this.workouts);
}

PeriodBucket _bucket(String label, Iterable<Workout> workouts) => PeriodBucket(
      label,
      workouts.fold<double>(0, (s, w) => s + w.totalVolume),
      workouts.fold<int>(0, (s, w) => s + w.duration.inMinutes),
      workouts.length,
    );

const List<String> weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// One bucket per day of the current week (Mon..Sun).
List<PeriodBucket> thisWeekBuckets(Iterable<Workout> workouts, {DateTime? now}) {
  final monday = mondayOf(now ?? DateTime.now());
  return List.generate(7, (i) {
    final day = DateTime(monday.year, monday.month, monday.day + i);
    return _bucket(weekdayNames[i], workouts.where((w) => _day(w.date) == day));
  });
}

/// One bucket per week for the last [weeks] weeks, oldest first.
List<PeriodBucket> recentWeekBuckets(Iterable<Workout> workouts, {DateTime? now, int weeks = 5}) {
  final monday = mondayOf(now ?? DateTime.now());
  return List.generate(weeks, (i) {
    final back = weeks - 1 - i;
    final start = DateTime(monday.year, monday.month, monday.day - 7 * back);
    final end = DateTime(start.year, start.month, start.day + 7);
    return _bucket(
      shortDate(start),
      workouts.where((w) => !w.date.isBefore(start) && w.date.isBefore(end)),
    );
  });
}

/// Weeks in a row with at least one workout. The current week does not
/// break the streak until it is over.
int weekStreak(Iterable<Workout> workouts, {DateTime? now}) {
  final weeks = workouts.map((w) => mondayOf(w.date)).toSet();
  var week = mondayOf(now ?? DateTime.now());
  if (!weeks.contains(week)) week = DateTime(week.year, week.month, week.day - 7);
  var count = 0;
  while (weeks.contains(week)) {
    count++;
    week = DateTime(week.year, week.month, week.day - 7);
  }
  return count;
}

/// Days in a row with a workout, ending today or yesterday.
int dayStreak(Iterable<Workout> workouts, {DateTime? now}) {
  final days = workouts.map((w) => _day(w.date)).toSet();
  var day = _day(now ?? DateTime.now());
  if (!days.contains(day)) day = DateTime(day.year, day.month, day.day - 1);
  var count = 0;
  while (days.contains(day)) {
    count++;
    day = DateTime(day.year, day.month, day.day - 1);
  }
  return count;
}

/// Exercises whose latest best weight is higher than their first one.
int improvedExercises(Iterable<Workout> workouts) {
  var count = 0;
  for (final name in trackedExercises(workouts)) {
    final points = progressFor(workouts, name);
    if (points.length >= 2 && points.last.weight > points.first.weight) count++;
  }
  return count;
}

class Achievement {
  final String badge;
  final String title;
  final String description;
  final IconData icon;
  final double progress;

  const Achievement({
    required this.badge,
    required this.title,
    required this.description,
    required this.icon,
    required this.progress,
  });

  bool get unlocked => progress >= 1;
}

double _ratio(num value, num goal) => (value / goal).clamp(0.0, 1.0).toDouble();

List<Achievement> achievements(Iterable<Workout> workouts, {DateTime? now}) {
  final list = workouts.toList();
  final count = list.length;
  final volume = list.fold<double>(0, (s, w) => s + w.totalVolume);
  final streak = weekStreak(list, now: now);
  final improved = improvedExercises(list);

  return [
    Achievement(
      badge: '$streak',
      title: 'Streak $streak ${streak == 1 ? 'week' : 'weeks'}',
      description: 'Trained every week. Keep it going!',
      icon: Icons.local_fire_department,
      progress: _ratio(streak, 2),
    ),
    Achievement(
      badge: '1',
      title: 'First workout',
      description: 'The hardest step is done.',
      icon: Icons.flag,
      progress: _ratio(count, 1),
    ),
    Achievement(
      badge: '10',
      title: '10 workouts',
      description: '$count of 10 workouts logged.',
      icon: Icons.fitness_center,
      progress: _ratio(count, 10),
    ),
    Achievement(
      badge: '25',
      title: '25 workouts',
      description: '$count of 25 workouts logged.',
      icon: Icons.fitness_center,
      progress: _ratio(count, 25),
    ),
    Achievement(
      badge: '10K',
      title: '10K kg lifted',
      description: 'Total weight moved in all workouts.',
      icon: Icons.bolt,
      progress: _ratio(volume, 10000),
    ),
    Achievement(
      badge: '100K',
      title: '100K kg club',
      description: 'A hundred tonnes of iron.',
      icon: Icons.bolt,
      progress: _ratio(volume, 100000),
    ),
    Achievement(
      badge: 'PR',
      title: 'Record breaker',
      description: '$improved of 3 exercises got stronger.',
      icon: Icons.emoji_events,
      progress: _ratio(improved, 3),
    ),
  ];
}
