import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'workout_stats.dart';

String _jsonText(Object? value, {bool kg = false}) {
  if (value == null) return '';
  if (value is num) {
    if (kg) return formatKg(value.toDouble());
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }
  return '$value';
}

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
        'weight': weight.replaceAll(',', '.'),
      };

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: _jsonText(json['name']),
        sets: _jsonText(json['sets']),
        reps: _jsonText(json['reps']),
        weight: _jsonText(json['weight'], kg: true),
      );
}

/// One finished workout session.
class Workout {
  static int _nextId = 0;

  /// Server id (a number) once synced, otherwise a temporary local id.
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
  }) : id = id ?? 'local-${DateTime.now().microsecondsSinceEpoch}-${_nextId++}';

  /// True when the workout is stored on the server.
  bool get isSynced => int.tryParse(id) != null;

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

  /// Same JSON format as the Django API.
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'date': date.toUtc().toIso8601String(),
        'durationSeconds': duration.inSeconds,
        'exercises': exercises.map((e) => e.toJson()).toList(),
      };

  factory Workout.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['exercises'];
    return Workout(
      id: json['id'] == null ? null : '${json['id']}',
      name: (json['name'] as String?) ?? 'Workout',
      date: DateTime.tryParse('${json['date']}')?.toLocal() ?? DateTime.now(),
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

/// Six weeks of example training (Push / Legs / Pull), dated relative to today.
/// Used in tests. The server has the same data via `manage.py seed_demo`.
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

/// Single source of truth for workouts in the app.
///
/// The Django server is the main storage. A copy is kept on the phone, so the
/// app opens instantly and still works offline: workouts saved without a
/// connection are uploaded on the next sync.
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._();
  static final WorkoutStore instance = WorkoutStore._();

  static const String _cacheKey = 'workouts_cache_v2';

  List<Workout> _workouts = [];
  bool isSyncing = false;
  String? syncError;

  List<Workout> get workouts => List.unmodifiable(_workouts);

  int get unsyncedCount => _workouts.where((w) => !w.isSynced).length;

  /// Shows the copy stored on the phone (instant, works offline).
  Future<void> loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null) {
        _workouts = decodeWorkouts(raw);
        _sortNewestFirst();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Could not read the local copy: $e');
    }
  }

  Future<void> onLoggedIn() async {
    await loadCache();
    await refresh();
  }

  /// Uploads workouts saved offline, then downloads the full list.
  Future<bool> refresh() async {
    if (isSyncing) return false;
    isSyncing = true;
    syncError = null;
    notifyListeners();
    try {
      for (final pending in _workouts.where((w) => !w.isSynced).toList()) {
        final saved = await ApiClient.instance.createWorkout(pending);
        _replace(pending.id, saved);
      }
      _workouts = await ApiClient.instance.fetchWorkouts();
      _sortNewestFirst();
      await _saveCache();
      return true;
    } catch (e) {
      syncError = '$e';
      return false;
    } finally {
      isSyncing = false;
      notifyListeners();
    }
  }

  /// Saves the workout and returns the exercises that set a new personal record.
  /// It appears in the app immediately and is uploaded in the background.
  List<String> addWorkout(Workout workout) {
    final records = newPersonalRecords(_workouts, workout);
    _workouts.add(workout);
    _sortNewestFirst();
    notifyListeners();
    unawaited(_saveCache());
    unawaited(_upload(workout));
    return records;
  }

  bool removeWorkout(String id) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index < 0) return false;
    final removed = _workouts.removeAt(index);
    notifyListeners();
    unawaited(_saveCache());
    if (removed.isSynced) unawaited(_deleteOnServer(removed.id));
    return true;
  }

  /// Used by "Undo" after a delete: saves it again as a new workout.
  void restoreWorkout(Workout workout) {
    addWorkout(Workout(
      name: workout.name,
      date: workout.date,
      exercises: workout.exercises,
      duration: workout.duration,
    ));
  }

  /// Called on log out.
  Future<void> clear() async {
    _workouts = [];
    syncError = null;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (_) {}
  }

  Future<void> _upload(Workout workout) async {
    try {
      final saved = await ApiClient.instance.createWorkout(workout);
      _replace(workout.id, saved);
      syncError = null;
      notifyListeners();
      await _saveCache();
    } catch (_) {
      syncError = 'Saved on the phone. It will sync when the server is reachable.';
      notifyListeners();
    }
  }

  Future<void> _deleteOnServer(String id) async {
    try {
      await ApiClient.instance.deleteWorkout(id);
    } catch (e) {
      syncError = 'Could not delete on the server: $e';
      notifyListeners();
    }
  }

  void _replace(String oldId, Workout saved) {
    final index = _workouts.indexWhere((w) => w.id == oldId);
    if (index >= 0) {
      _workouts[index] = saved;
      _sortNewestFirst();
    } else {
      // Deleted on the phone while it was uploading: delete on the server too.
      unawaited(_deleteOnServer(saved.id));
    }
  }

  void _sortNewestFirst() => _workouts.sort((a, b) => b.date.compareTo(a.date));

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, encodeWorkouts(_workouts));
    } catch (e) {
      debugPrint('Could not save the local copy: $e');
    }
  }
}
