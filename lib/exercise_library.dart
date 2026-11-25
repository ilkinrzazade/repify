import 'dart:convert';

import 'package:http/http.dart' as http;

import 'workout_stats.dart';

/// Exercise pictures and step-by-step instructions come from the open
/// "free-exercise-db" dataset (public domain, Unlicense):
/// https://github.com/yuhonas/free-exercise-db
const String exerciseDbBase =
    'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main';

/// Our exercise names -> ids in free-exercise-db.
const Map<String, String> exerciseDbIds = {
  'Bench Press': 'Barbell_Bench_Press_-_Medium_Grip',
  'Incline Bench Press': 'Barbell_Incline_Bench_Press_-_Medium_Grip',
  'Dumbbell Bench Press': 'Dumbbell_Bench_Press',
  'Chest Fly': 'Dumbbell_Flyes',
  'Cable Crossover': 'Cable_Crossover',
  'Push-up': 'Pushups',
  'Dips': 'Dips_-_Chest_Version',
  'Deadlift': 'Barbell_Deadlift',
  'Pull-up': 'Pullups',
  'Lat Pulldown': 'Wide-Grip_Lat_Pulldown',
  'Barbell Row': 'Bent_Over_Barbell_Row',
  'Seated Cable Row': 'Seated_Cable_Rows',
  'Dumbbell Row': 'One-Arm_Dumbbell_Row',
  'Squat': 'Barbell_Full_Squat',
  'Leg Press': 'Leg_Press',
  'Lunges': 'Dumbbell_Lunges',
  'Romanian Deadlift': 'Romanian_Deadlift',
  'Leg Extension': 'Leg_Extensions',
  'Leg Curl': 'Lying_Leg_Curls',
  'Calf Raise': 'Standing_Calf_Raises',
  'Overhead Press': 'Barbell_Shoulder_Press',
  'Dumbbell Shoulder Press': 'Dumbbell_Shoulder_Press',
  'Lateral Raise': 'Side_Lateral_Raise',
  'Rear Delt Fly': 'Bent_Over_Dumbbell_Rear_Delt_Raise_With_Head_On_Bench',
  'Face Pull': 'Face_Pull',
  'Biceps Curl': 'Dumbbell_Bicep_Curl',
  'Hammer Curl': 'Hammer_Curls',
  'Preacher Curl': 'Preacher_Curl',
  'Triceps Pushdown': 'Triceps_Pushdown',
  'Skull Crusher': 'EZ-Bar_Skullcrusher',
  'Plank': 'Plank',
  'Crunch': 'Crunches',
  'Hanging Leg Raise': 'Hanging_Leg_Raise',
  'Russian Twist': 'Russian_Twist',
};

String? exerciseDbId(String exercise) {
  final key = normalizeExerciseName(exercise);
  for (final entry in exerciseDbIds.entries) {
    if (normalizeExerciseName(entry.key) == key) return entry.value;
  }
  return null;
}

/// Start and end position pictures of an exercise (empty for custom exercises).
List<String> exerciseImageUrls(String exercise) {
  final id = exerciseDbId(exercise);
  if (id == null) return const [];
  return [
    '$exerciseDbBase/exercises/$id/0.jpg',
    '$exerciseDbBase/exercises/$id/1.jpg',
  ];
}

/// YouTube search for a form tutorial of the exercise.
Uri videoTutorialUri(String exercise) => Uri.https(
      'www.youtube.com',
      '/results',
      {'search_query': '$exercise proper form tutorial'},
    );

class ExerciseDetails {
  final List<String> instructions;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String? level;
  final String? equipment;

  const ExerciseDetails({
    required this.instructions,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.level,
    this.equipment,
  });

  factory ExerciseDetails.fromJson(Map<String, dynamic> json) {
    List<String> list(Object? value) =>
        value is List ? value.map((v) => '$v').toList() : <String>[];
    String? text(Object? value) =>
        value == null || '$value'.trim().isEmpty ? null : '$value';
    return ExerciseDetails(
      instructions: list(json['instructions']),
      primaryMuscles: list(json['primaryMuscles']),
      secondaryMuscles: list(json['secondaryMuscles']),
      level: text(json['level']),
      equipment: text(json['equipment']),
    );
  }
}

/// Downloads the dataset once per app session and keeps it in memory.
class ExerciseLibrary {
  ExerciseLibrary._();

  static Map<String, ExerciseDetails>? _byId;

  static Future<ExerciseDetails?> detailsFor(String exercise) async {
    final id = exerciseDbId(exercise);
    if (id == null) return null;
    _byId ??= await _download();
    return _byId![id];
  }

  static Future<Map<String, ExerciseDetails>> _download() async {
    final response = await http
        .get(Uri.parse('$exerciseDbBase/dist/exercises.json'))
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw Exception('Exercise library error ${response.statusCode}');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    final result = <String, ExerciseDetails>{};
    if (data is List) {
      for (final item in data.whereType<Map>()) {
        final json = Map<String, dynamic>.from(item);
        final id = json['id'];
        if (id is String) result[id] = ExerciseDetails.fromJson(json);
      }
    }
    return result;
  }
}
