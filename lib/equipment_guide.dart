import 'package:flutter/material.dart';

import 'workout_stats.dart';

/// A piece of gym equipment and the exercises you can do with it.
class Equipment {
  final String name;
  final IconData icon;
  final List<String> muscles;
  final List<String> exercises;

  const Equipment({
    required this.name,
    required this.icon,
    required this.muscles,
    required this.exercises,
  });
}

/// Offline equipment guide. Exercise names match the exercise catalog.
const List<Equipment> equipmentGuide = [
  Equipment(
    name: 'Dumbbells',
    icon: Icons.fitness_center,
    muscles: ['Chest', 'Shoulders', 'Arms', 'Back', 'Legs'],
    exercises: [
      'Dumbbell Bench Press', 'Dumbbell Shoulder Press', 'Dumbbell Row',
      'Biceps Curl', 'Hammer Curl', 'Lateral Raise', 'Lunges',
    ],
  ),
  Equipment(
    name: 'Barbell',
    icon: Icons.horizontal_rule,
    muscles: ['Legs', 'Back', 'Chest', 'Shoulders'],
    exercises: [
      'Squat', 'Deadlift', 'Bench Press', 'Barbell Row',
      'Overhead Press', 'Romanian Deadlift', 'Skull Crusher',
    ],
  ),
  Equipment(
    name: 'Bench',
    icon: Icons.weekend_outlined,
    muscles: ['Chest', 'Arms'],
    exercises: ['Bench Press', 'Incline Bench Press', 'Dumbbell Bench Press', 'Chest Fly'],
  ),
  Equipment(
    name: 'Cable Machine',
    icon: Icons.cable,
    muscles: ['Chest', 'Arms', 'Shoulders', 'Back'],
    exercises: ['Cable Crossover', 'Triceps Pushdown', 'Face Pull', 'Seated Cable Row'],
  ),
  Equipment(
    name: 'Lat Pulldown Machine',
    icon: Icons.vertical_align_bottom,
    muscles: ['Back', 'Arms'],
    exercises: ['Lat Pulldown'],
  ),
  Equipment(
    name: 'Leg Press Machine',
    icon: Icons.airline_seat_legroom_extra,
    muscles: ['Legs'],
    exercises: ['Leg Press', 'Calf Raise'],
  ),
  Equipment(
    name: 'Leg Extension / Curl Machine',
    icon: Icons.accessible_forward,
    muscles: ['Legs'],
    exercises: ['Leg Extension', 'Leg Curl'],
  ),
  Equipment(
    name: 'Pull-up Bar',
    icon: Icons.drag_handle,
    muscles: ['Back', 'Arms', 'Core'],
    exercises: ['Pull-up', 'Hanging Leg Raise'],
  ),
  Equipment(
    name: 'Dip Station',
    icon: Icons.unfold_more,
    muscles: ['Chest', 'Arms'],
    exercises: ['Dips'],
  ),
  Equipment(
    name: 'Exercise Mat',
    icon: Icons.self_improvement,
    muscles: ['Core', 'Chest'],
    exercises: ['Plank', 'Crunch', 'Russian Twist', 'Push-up'],
  ),
];

/// One-line technique cue for each exercise.
const Map<String, String> exerciseTips = {
  'Bench Press': 'Feet flat, shoulder blades squeezed, lower the bar to mid-chest.',
  'Incline Bench Press': 'Bench at 30–45°, press up and slightly back over the shoulders.',
  'Dumbbell Bench Press': 'Lower the dumbbells slowly to chest level, press up together.',
  'Chest Fly': 'Slight bend in the elbows, open wide and squeeze the chest.',
  'Cable Crossover': 'Step forward, bring the handles together in a hugging motion.',
  'Push-up': 'Body in a straight line, chest close to the floor.',
  'Dips': 'Lean forward a little for chest, stay upright for triceps.',
  'Deadlift': 'Flat back, bar close to the legs, push the floor away.',
  'Pull-up': 'Full hang at the bottom, chin over the bar at the top.',
  'Lat Pulldown': 'Pull the bar to the upper chest, elbows down and back.',
  'Barbell Row': 'Hinge at the hips, pull the bar to the lower ribs.',
  'Seated Cable Row': 'Chest up, pull to the belly, squeeze the shoulder blades.',
  'Dumbbell Row': 'One hand on the bench, pull the dumbbell to the hip.',
  'Squat': 'Chest up, knees follow the toes, go to at least parallel.',
  'Leg Press': 'Feet shoulder-width, do not lock the knees at the top.',
  'Lunges': 'Long step, back knee almost touches the floor.',
  'Romanian Deadlift': 'Soft knees, push the hips back, feel the hamstrings stretch.',
  'Leg Extension': 'Straighten the legs fully, lower slowly.',
  'Leg Curl': 'Curl the heels toward you, control the way back.',
  'Calf Raise': 'Full stretch at the bottom, pause at the top.',
  'Overhead Press': 'Tight core, press the bar straight over the head.',
  'Dumbbell Shoulder Press': 'Start at ear level, press up without arching the back.',
  'Lateral Raise': 'Raise to shoulder height, lead with the elbows.',
  'Rear Delt Fly': 'Bend forward, open the arms wide with light weight.',
  'Face Pull': 'Pull the rope toward the face, elbows high.',
  'Biceps Curl': 'Elbows still at the sides, no swinging.',
  'Hammer Curl': 'Palms face each other, curl with control.',
  'Preacher Curl': 'Upper arms on the pad, lower all the way down.',
  'Triceps Pushdown': 'Elbows fixed at the sides, push down until arms are straight.',
  'Skull Crusher': 'Lower the bar to the forehead, only the elbows move.',
  'Plank': 'Straight line from head to heels, tight core.',
  'Crunch': 'Lift the shoulders, keep the lower back on the floor.',
  'Hanging Leg Raise': 'No swinging, raise the legs with the abs.',
  'Russian Twist': 'Lean back slightly, rotate from the torso.',
};

String? tipFor(String exercise) {
  final key = normalizeExerciseName(exercise);
  for (final entry in exerciseTips.entries) {
    if (normalizeExerciseName(entry.key) == key) return entry.value;
  }
  return null;
}

/// Finds a guide entry for a name returned by the AI (e.g. "dumbbell" -> Dumbbells).
Equipment? findEquipment(String name) {
  final key = normalizeExerciseName(name);
  if (key.isEmpty) return null;
  for (final e in equipmentGuide) {
    final guideKey = normalizeExerciseName(e.name);
    if (guideKey == key || guideKey.contains(key) || key.contains(guideKey)) {
      return e;
    }
  }
  return null;
}
