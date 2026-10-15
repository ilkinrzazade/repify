import 'dart:async';
import 'package:flutter/material.dart';
import 'workout_store.dart';

String _two(int n) => n.toString().padLeft(2, '0');

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
  final exerciseController = TextEditingController();
  final setsController = TextEditingController();
  final repsController = TextEditingController();
  final weightController = TextEditingController();

  final List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
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
    exerciseController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

  String get timerText =>
      '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes.remainder(60))}:${_two(elapsed.inSeconds.remainder(60))}';

  String get startedText =>
      'Started at ${_two(startTime.hour)}:${_two(startTime.minute)}';

  int get volumeSoFar =>
      exercises.fold<double>(0, (sum, e) => sum + e.volume).round();

  void showMessage(String text, {Color? color}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }

  void addExercise() {
    if (exerciseController.text.trim().isEmpty ||
        setsController.text.trim().isEmpty ||
        repsController.text.trim().isEmpty ||
        weightController.text.trim().isEmpty) {
      showMessage(
        'Please fill in exercise name, sets, reps and weight',
        color: Colors.red,
      );
      return;
    }
    setState(() {
      exercises.add(
        Exercise(
          name: exerciseController.text.trim(),
          sets: setsController.text.trim(),
          reps: repsController.text.trim(),
          weight: weightController.text.trim(),
        ),
      );
      exerciseController.clear();
      setsController.clear();
      repsController.clear();
      weightController.clear();
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
      name: typedName.isEmpty ? 'Workout' : typedName,
      date: startTime,
      exercises: List.of(exercises),
      duration: DateTime.now().difference(startTime),
    );
    WorkoutStore.instance.addWorkout(workout);

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Workout saved: ${workout.formattedDuration} · ${workout.formattedVolume}',
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
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Workout name (e.g. Leg Day)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Log an exercise',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: exerciseController,
                    decoration: const InputDecoration(
                      labelText: 'Exercise name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: setsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sets',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: repsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Reps',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Weight (kg)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add exercise'),
                  ),
                  const SizedBox(height: 16),
                  if (exercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No exercises yet. Log your first one above.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
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