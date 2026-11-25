import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'workout_stats.dart';

/// One exercise inside a workout, e.g. Bench Press 3 x 10 @ 60 kg.
class Exercise {
  final String name;
  final String sets;
  final String reps;
  final String weight;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.weight,
  });

  /// Weight as a number. Accepts both "77.5" and "77,5".
  double get weightKg => double.tryParse(weight.replaceAll(',', '.')) ?? 0;

  /// Total weight moved in this exercise: sets x reps x weight (kg).
  double get volume {
    final s = double.tryParse(sets) ?? 0;
    final r = double.tryParse(reps) ?? 0;
    return s * r * weightKg;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sets': sets,
        'reps': reps,
        'weight': weight,
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: '${json['name'] ?? ''}',
        sets: '${json['sets'] ?? ''}',
        reps: '${json['reps'] ?? ''}',
        weight: '${json['weight'] ?? ''}',
      );
}

/// One finished workout session.
class Workout {
  static int _nextId = 0;

  final String id;
  final String name;
  final DateTime date;
  final List<Exercise> exercises;
  final Duration duration;

  Workout({
    String? id,
    required this.name,
    required this.date,
    required this.exercises,
    this.duration = Duration.zero,
  }) : id = id ?? '${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  String get formattedDate => '${shortDate(date)}, ${date.year}';

  bool get hasDuration => duration.inSeconds > 0;

  String get formattedDuration {
    if (duration.inMinutes == 0) return '${duration.inSeconds} sec';
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
    return '$m min';
  }

  double get totalVolume =>
      exercises.fold<double>(0, (sum, e) => sum + e.volume);

  String get formattedVolume {
    final digits = totalVolume.round().toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '$withCommas kg';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return Workout(
      id: json['id'] as String?,
      name: (json['name'] as String?) ?? 'Workout',
      date: DateTime.tryParse('${json['date']}') ?? DateTime.now(),
      duration: Duration(
        seconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      ),
      exercises: rawExercises is List
          ? rawExercises
              .whereType<Map>()
              .map((e) => Exercise.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <Exercise>[],
    );
  }
}

String encodeWorkouts(List<Workout> workouts) =>
    jsonEncode(workouts.map((w) => w.toJson()).toList());

List<Workout> decodeWorkouts(String raw) {
  final data = jsonDecode(raw);
  if (data is! List) return [];
  return data
      .whereType<Map>()
      .map((w) => Workout.fromJson(Map<String, dynamic>.from(w)))
      .toList();
}

/// Six weeks of example training (Push / Legs / Pull), dated relative to today
/// so the dashboard and the progress chart look realistic in a demo.
List<Workout> sampleWorkouts() {
  final now = DateTime.now();
  DateTime daysAgo(int days) =>
      DateTime(now.year, now.month, now.day, 18).subtract(Duration(days: days));

  const bench = [60.0, 65.0, 70.0, 72.5, 77.5, 82.5];
  const squat = [80.0, 85.0, 90.0, 95.0, 100.0, 105.0];
  const deadlift = [100.0, 105.0, 112.5, 117.5, 122.5, 127.5];

  final workouts = <Workout>[];
  for (var week = 0; week < 6; week++) {
    final offset = 7 * week;
    workouts.add(Workout(
      name: 'Push Day',
      date: daysAgo(40 - offset),
      duration: Duration(minutes: 50 + week),
      exercises: [
        Exercise(name: 'Bench Press', sets: '4', reps: '8', weight: formatKg(bench[week])),
        Exercise(name: 'Overhead Press', sets: '3', reps: '10', weight: formatKg(35 + 2.5 * week)),
        const Exercise(name: 'Triceps Pushdown', sets: '3', reps: '12', weight: '25'),
      ],
    ));
    workouts.add(Workout(
      name: 'Leg Day',
      date: daysAgo(38 - offset),
      duration: Duration(minutes: 58 + week),
      exercises: [
        Exercise(name: 'Squat', sets: '4', reps: '8', weight: formatKg(squat[week])),
        Exercise(name: 'Leg Press', sets: '3', reps: '12', weight: formatKg(160 + 10.0 * week)),
        const Exercise(name: 'Leg Curl', sets: '3', reps: '12', weight: '40'),
      ],
    ));
    workouts.add(Workout(
      name: 'Pull Day',
      date: daysAgo(36 - offset),
      duration: Duration(minutes: 62 + week),
      exercises: [
        Exercise(name: 'Deadlift', sets: '3', reps: '5', weight: formatKg(deadlift[week])),
        Exercise(name: 'Lat Pulldown', sets: '3', reps: '10', weight: formatKg(50 + 2.5 * week)),
        Exercise(name: 'Barbell Row', sets: '3', reps: '10', weight: formatKg(60 + 2.5 * week)),
      ],
    ));
  }
  workouts.sort((a, b) => b.date.compareTo(a.date));
  return workouts;
}

/// Single source of truth for workouts.
/// Data is saved on the phone (shared_preferences), so it survives a restart.
/// In a later iteration only this class needs to change to use a backend API.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._() : _workouts = sampleWorkouts();
  static final WorkoutStore instance = WorkoutStore._();

  static const String _storageKey = 'workouts_v1';

  List<Workout> _workouts;

  List<Workout> get workouts => List.unmodifiable(_workouts);

  /// Reads saved workouts. If nothing is saved yet, sample data stays.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null) {
        _workouts = decodeWorkouts(raw);
        _sortNewestFirst();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Could not load workouts: $e');
    }
  }

  /// Saves the workout and returns the exercises that set a new personal record.
  List<String> addWorkout(Workout workout) {
    final records = newPersonalRecords(_workouts, workout);
    _workouts.add(workout);
    _sortNewestFirst();
    notifyListeners();
    unawaited(_save());
    return records;
  }

  bool removeWorkout(String id) {
    final before = _workouts.length;
    _workouts.removeWhere((w) => w.id == id);
    if (_workouts.length == before) return false;
    notifyListeners();
    unawaited(_save());
    return true;
  }

  /// Used by "Undo" after a delete.
  void restoreWorkout(Workout workout) {
    if (_workouts.any((w) => w.id == workout.id)) return;
    _workouts.add(workout);
    _sortNewestFirst();
    notifyListeners();
    unawaited(_save());
  }

  Future<void> resetToSampleData() async {
    _workouts = sampleWorkouts();
    notifyListeners();
    await _save();
  }

  void _sortNewestFirst() => _workouts.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, encodeWorkouts(_workouts));
    } catch (e) {
      debugPrint('Could not save workouts: $e');
    }
  }
}
