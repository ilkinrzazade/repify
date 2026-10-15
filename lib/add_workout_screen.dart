import 'package:flutter/material.dart';
import 'workout_store.dart';

class AddWorkoutScreen extends StatefulWidget {
  final VoidCallback onSaved;

  const AddWorkoutScreen({super.key, required this.onSaved});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  final workoutNameController = TextEditingController();
  final exerciseController = TextEditingController();
  final setsController = TextEditingController();
  final repsController = TextEditingController();
  final weightController = TextEditingController();

  final List<Exercise> addedExercises = [];

  @override
  void dispose() {
    workoutNameController.dispose();
    exerciseController.dispose();
    setsController.dispose();
    repsController.dispose();
    weightController.dispose();
    super.dispose();
  }

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
      addedExercises.add(
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

  void saveWorkout() {
    final typedName = workoutNameController.text.trim();
    WorkoutStore.instance.addWorkout(
      Workout(
        name: typedName.isEmpty ? 'Workout' : typedName,
        date: DateTime.now(),
        exercises: List.of(addedExercises),
      ),
    );
    setState(() {
      addedExercises.clear();
      workoutNameController.clear();
    });
    showMessage('Workout saved!');
    widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: workoutNameController,
            decoration: const InputDecoration(
              labelText: 'Workout name (e.g. Leg Day)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: exerciseController,
            decoration: const InputDecoration(
              labelText: 'Exercise name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
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
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addExercise,
              child: const Text('Add Exercise'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: addedExercises.length,
              itemBuilder: (context, index) {
                final ex = addedExercises[index];
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
                          addedExercises.removeAt(index);
                        });
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: addedExercises.isEmpty ? null : saveWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Save Workout', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}