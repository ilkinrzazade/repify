import 'package:flutter/material.dart';

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

  /// Total weight moved in this exercise: sets x reps x weight (kg).
  double get volume {
    final s = double.tryParse(sets) ?? 0;
    final r = double.tryParse(reps) ?? 0;
    final w = double.tryParse(weight.replaceAll(',', '.')) ?? 0;
    return s * r * w;
  }
}

class Workout {
  final String name;
  final DateTime date;
  final List<Exercise> exercises;
  final Duration duration;

  const Workout({
    required this.name,
    required this.date,
    required this.exercises,
    this.duration = Duration.zero,
  });

  String get formattedDate {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

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
}

/// Single source of truth for workouts.
/// In Iteration 2 only this class will change (API calls instead of a list).
class WorkoutStore extends ChangeNotifier {
  WorkoutStore._();
  static final WorkoutStore instance = WorkoutStore._();

  final List<Workout> _workouts = [
    Workout(
      name: 'Leg Day',
      date: DateTime(2026, 9, 20),
      duration: const Duration(minutes: 62),
      exercises: const [
        Exercise(name: 'Squat', sets: '4', reps: '8', weight: '100'),
        Exercise(name: 'Leg Press', sets: '3', reps: '12', weight: '180'),
        Exercise(name: 'Leg Curl', sets: '3', reps: '12', weight: '40'),
      ],
    ),
    Workout(
      name: 'Push Day',
      date: DateTime(2026, 9, 18),
      duration: const Duration(minutes: 55),
      exercises: const [
        Exercise(name: 'Bench Press', sets: '4', reps: '8', weight: '80'),
        Exercise(name: 'Overhead Press', sets: '3', reps: '10', weight: '40'),
        Exercise(name: 'Triceps Pushdown', sets: '3', reps: '12', weight: '25'),
      ],
    ),
    Workout(
      name: 'Pull Day',
      date: DateTime(2026, 9, 16),
      duration: const Duration(minutes: 68),
      exercises: const [
        Exercise(name: 'Deadlift', sets: '3', reps: '5', weight: '120'),
        Exercise(name: 'Lat Pulldown', sets: '3', reps: '10', weight: '60'),
        Exercise(name: 'Barbell Row', sets: '3', reps: '10', weight: '70'),
      ],
    ),
    Workout(
      name: 'Leg Day',
      date: DateTime(2026, 9, 13),
      duration: const Duration(minutes: 58),
      exercises: const [
        Exercise(name: 'Squat', sets: '4', reps: '8', weight: '95'),
        Exercise(name: 'Lunges', sets: '3', reps: '12', weight: '20'),
      ],
    ),
    Workout(
      name: 'Push Day',
      date: DateTime(2026, 9, 11),
      duration: const Duration(minutes: 50),
      exercises: const [
        Exercise(name: 'Bench Press', sets: '4', reps: '8', weight: '77.5'),
        Exercise(name: 'Incline Press', sets: '3', reps: '10', weight: '30'),
      ],
    ),
  ];

  List<Workout> get workouts => List.unmodifiable(_workouts);

  void addWorkout(Workout workout) {
    _workouts.insert(0, workout);
    notifyListeners();
  }
}