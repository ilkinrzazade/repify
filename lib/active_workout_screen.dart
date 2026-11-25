import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'exercise_catalog.dart';
import 'exercise_picker_sheet.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Live workout session: a timer runs while the user logs exercises.
/// Exercises are picked from a list and sets/reps/weight use +/- buttons,
/// so no typing is needed.
class ActiveWorkoutScreen extends StatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final DateTime startTime = DateTime.now();
  late final Timer timer;
  Duration elapsed = Duration.zero;

  final nameController = TextEditingController();
  final List<Exercise> exercises = [];

  // The exercise currently being prepared.
  String? currentExercise;
  Exercise? lastTime;
  int sets = 3;
  int reps = 10;
  double weight = 20;

  @override
  void initState() {
    super.initState();
    // Recalculate from the start time every second, so the timer stays exact.
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        elapsed = DateTime.now().difference(startTime);
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    nameController.dispose();
    super.dispose();
  }

  String get timerText =>
      '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes.remainder(60))}:${_two(elapsed.inSeconds.remainder(60))}';

  String get startedText =>
      'Started at ${_two(startTime.hour)}:${_two(startTime.minute)}';

  int get volumeSoFar =>
      exercises.fold<double>(0, (sum, e) => sum + e.volume).round();

  String get autoName => suggestedWorkoutName(exercises.map((e) => e.name));

  void showMessage(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  Future<void> pickExercise() async {
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ExercisePickerSheet(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    selectExercise(name.trim());
  }

  /// Opens the editor for [name], pre-filled with the last values used.
  void selectExercise(String name) {
    final key = normalizeExerciseName(name);
    Exercise? previous;
    for (final e in exercises.reversed) {
      if (normalizeExerciseName(e.name) == key) {
        previous = e;
        break;
      }
    }
    final fromHistory = lastExerciseFor(WorkoutStore.instance.workouts, name);
    previous ??= fromHistory;

    setState(() {
      currentExercise = name;
      lastTime = fromHistory;
      sets = int.tryParse(previous?.sets ?? '') ?? 3;
      reps = int.tryParse(previous?.reps ?? '') ?? 10;
      weight = previous?.weightKg ?? 20.0;
    });
  }

  Future<void> editWeight() async {
    final controller = TextEditingController(text: formatKg(weight));
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Weight (kg)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(suffixText: 'kg'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (result == null || !mounted) return;
    setState(() => weight = math.min(500.0, math.max(0.0, result)));
  }

  void addExercise() {
    final name = currentExercise;
    if (name == null) {
      showMessage('Choose an exercise first', color: Colors.red);
      return;
    }
    setState(() {
      exercises.add(
        Exercise(
          name: name,
          sets: '$sets',
          reps: '$reps',
          weight: formatKg(weight),
        ),
      );
      currentExercise = null;
      lastTime = null;
    });
  }

  void finish() {
    if (exercises.isEmpty) {
      showMessage('Add at least one exercise first', color: Colors.red);
      return;
    }
    timer.cancel();
    final typedName = nameController.text.trim();
    final workout = Workout(
      name: typedName.isEmpty ? autoName : typedName,
      date: startTime,
      exercises: List.of(exercises),
      duration: DateTime.now().difference(startTime),
    );
    final records = WorkoutStore.instance.addWorkout(workout);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: records.isEmpty ? null : Colors.green.shade700,
        content: Text(
          records.isEmpty
              ? '${workout.name} saved: ${workout.formattedDuration} · ${workout.formattedVolume}'
              : '🏆 New personal record: ${records.join(', ')}!',
        ),
      ),
    );
  }

  Future<void> confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Discard workout?'),
        content: const Text('Your current session will not be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildEditor() {
    final last = lastTime;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    currentExercise!,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton(onPressed: pickExercise, child: const Text('Change')),
              ],
            ),
            Text(
              last != null
                  ? 'Last time: ${last.sets} × ${last.reps} · ${last.weight} kg'
                  : 'First time doing this exercise',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StepperTile(
                    label: 'Sets',
                    value: '$sets',
                    onMinus: () => setState(() => sets = math.max(1, sets - 1)),
                    onPlus: () => setState(() => sets = math.min(20, sets + 1)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StepperTile(
                    label: 'Reps',
                    value: '$reps',
                    onMinus: () => setState(() => reps = math.max(1, reps - 1)),
                    onPlus: () => setState(() => reps = math.min(100, reps + 1)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _StepperTile(
              label: 'Weight (kg) · tap the number to type',
              value: formatKg(weight),
              onMinus: () => setState(() => weight = math.max(0.0, weight - 2.5)),
              onPlus: () => setState(() => weight = math.min(500.0, weight + 2.5)),
              onTapValue: editWeight,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: addExercise,
              icon: const Icon(Icons.add),
              label: const Text('Add to workout'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Workout in progress'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Discard',
              onPressed: confirmDiscard,
            ),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4A2574), Color(0xFF7E57C2)],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'ELAPSED TIME',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    timerText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$startedText · ${exercises.length} exercises · $volumeSoFar kg so far',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Workout name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetWorkoutNames.map((preset) {
                      return ChoiceChip(
                        label: Text(preset),
                        selected: nameController.text == preset,
                        onSelected: (selected) => setState(() {
                          nameController.text = selected ? preset : '';
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Custom name (optional)',
                      helperText: exercises.isEmpty
                          ? 'Leave empty to name it automatically'
                          : 'Leave empty to use: $autoName',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Log an exercise',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (currentExercise == null)
                    OutlinedButton.icon(
                      onPressed: pickExercise,
                      icon: const Icon(Icons.fitness_center),
                      label: const Text('Choose exercise'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    )
                  else
                    _buildEditor(),
                  const SizedBox(height: 16),
                  if (exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No exercises yet. Choose your first one above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Tap an exercise to log it again with the same values.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ...List.generate(exercises.length, (index) {
                    final ex = exercises[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(ex.name),
                        subtitle: Text(
                          '${ex.sets} sets × ${ex.reps} reps · ${ex.weight} kg',
                        ),
                        onTap: () => selectExercise(ex.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              exercises.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.check),
                label: const Text(
                  'Finish workout',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A number with − and + buttons, e.g. "Sets  − 3 +".
class _StepperTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback? onTapValue;

  const _StepperTile({
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    this.onTapValue,
  });

  @override
  Widget build(BuildContext context) {
    final number = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Row(
            children: [
              IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove_circle_outline),
                tooltip: 'Less',
              ),
              Expanded(
                child: onTapValue == null
                    ? Center(child: number)
                    : InkWell(
                        onTap: onTapValue,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Center(child: number),
                        ),
                      ),
              ),
              IconButton(
                onPressed: onPlus,
                icon: const Icon(Icons.add_circle_outline),
                tooltip: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
