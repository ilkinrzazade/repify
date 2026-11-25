import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'coach.dart';
import 'exercise_catalog.dart';
import 'exercise_overview_screen.dart';
import 'exercise_picker_sheet.dart';
import 'health_service.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

String _two(int n) => n.toString().padLeft(2, '0');

/// Workout session.
/// Live mode: a timer runs while the user logs exercises.
/// Past mode ([pastMode]): no timer, the user picks the date and duration.
/// Exercises are picked from a list and sets/reps/weight use +/- buttons.
class ActiveWorkoutScreen extends StatefulWidget {
  /// Optional exercise to open right away (e.g. from the equipment scanner).
  final String? initialExercise;

  /// Optional workout name (e.g. from a quick-start template).
  final String? initialName;

  /// Log a workout that already happened.
  final bool pastMode;

  const ActiveWorkoutScreen({
    super.key,
    this.initialExercise,
    this.initialName,
    this.pastMode = false,
  });

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final DateTime startTime = DateTime.now();
  Timer? timer;
  Duration elapsed = Duration.zero;

  // Past mode values.
  DateTime pastDate = DateTime.now().subtract(const Duration(days: 1));
  int pastMinutes = 60;

  final nameController = TextEditingController();
  final List<Exercise> exercises = [];

  // The exercise currently being prepared.
  String? currentExercise;
  Exercise? lastTime;
  int sets = 3;
  int reps = 10;
  double weight = 20;

  bool get pastMode => widget.pastMode;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.initialName ?? '';
    if (!pastMode) {
      // Recalculate from the start time every second, so the timer stays exact.
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          elapsed = DateTime.now().difference(startTime);
        });
      });
    }
    final first = widget.initialExercise;
    if (first != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) selectExercise(first);
      });
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    nameController.dispose();
    super.dispose();
  }

  String get timerText =>
      '${_two(elapsed.inHours)}:${_two(elapsed.inMinutes.remainder(60))}:${_two(elapsed.inSeconds.remainder(60))}';

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

  Future<void> pickPastDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: pastDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => pastDate = picked);
  }

  void addExercise() {
    final name = currentExercise;
    if (name == null) {
      showMessage('Choose an exercise first', color: AppColors.danger);
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
      showMessage('Add at least one exercise first', color: AppColors.danger);
      return;
    }
    timer?.cancel();
    final typedName = nameController.text.trim();
    final DateTime date;
    final Duration duration;
    if (pastMode) {
      date = DateTime(pastDate.year, pastDate.month, pastDate.day, 18);
      duration = Duration(minutes: pastMinutes);
    } else {
      date = startTime;
      duration = DateTime.now().difference(startTime);
    }
    final workout = Workout(
      name: typedName.isEmpty ? autoName : typedName,
      date: date,
      exercises: List.of(exercises),
      duration: duration,
    );
    final records = WorkoutStore.instance.addWorkout(workout);
    // Also save it to Health Connect (if connected), in the background.
    unawaited(HealthService.instance.saveWorkout(workout));

    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: records.isEmpty ? null : AppColors.lime,
        content: Text(
          records.isEmpty
              ? '${workout.name} saved: ${workout.formattedDuration} · ${workout.formattedVolume}'
              : '🏆 New personal record: ${records.join(', ')}!',
          style: records.isEmpty
              ? null
              : const TextStyle(color: AppColors.onLime, fontWeight: FontWeight.w800),
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

  // ---------- UI ----------

  Widget _buildLiveHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.lime.withAlpha(90)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE · DURATION',
                style: TextStyle(color: AppColors.muted, fontSize: 12, letterSpacing: 1.6),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              timerText,
              style: const TextStyle(
                color: AppColors.lime,
                fontSize: 58,
                fontWeight: FontWeight.w900,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  icon: Icons.schedule,
                  value: '${_two(startTime.hour)}:${_two(startTime.minute)}',
                  label: 'Started',
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  icon: Icons.list_alt,
                  value: '${exercises.length}',
                  label: 'Exercises',
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  icon: Icons.bolt,
                  value: compactNumber(volumeSoFar),
                  label: 'kg lifted',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPastHeader() {
    final date = '${shortDate(pastDate)}, ${pastDate.year}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.lime.withAlpha(90)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'LOG A PAST WORKOUT',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted, fontSize: 12, letterSpacing: 1.6),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: pickPastDate,
            icon: const Icon(Icons.calendar_month, color: AppColors.lime),
            label: Text(date, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          _StepperTile(
            label: 'Duration (minutes)',
            value: '$pastMinutes',
            onMinus: () => setState(() => pastMinutes = math.max(5, pastMinutes - 5)),
            onPlus: () => setState(() => pastMinutes = math.min(300, pastMinutes + 5)),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor() {
    final last = lastTime;
    final suggestion = suggestNext(last);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  currentExercise!,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'How to do it',
                icon: const Icon(Icons.info_outline, color: AppColors.lime),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseOverviewScreen(
                      exercise: currentExercise!,
                      showStartButton: false,
                    ),
                  ),
                ),
              ),
              TextButton(onPressed: pickExercise, child: const Text('Change')),
            ],
          ),
          Text(
            last != null
                ? 'Last time: ${last.sets} × ${last.reps} · ${last.weight} kg'
                : 'First time doing this exercise',
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 10),
            _CoachCard(
              suggestion: suggestion,
              applied: weight == suggestion.weight && reps == suggestion.reps,
              onApply: () => setState(() {
                weight = suggestion.weight;
                reps = suggestion.reps;
              }),
            ),
          ],
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
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(color: AppColors.text, fontSize: 17, fontWeight: FontWeight.w800),
      );

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
          title: Text(pastMode ? 'Log workout' : 'Workout in progress'),
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Discard',
              onPressed: confirmDiscard,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            pastMode ? _buildPastHeader() : _buildLiveHeader(),
            const SizedBox(height: 22),
            _sectionTitle('Workout name'),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            TextField(
              controller: nameController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                labelText: 'Custom name (optional)',
                helperText: exercises.isEmpty
                    ? 'Leave empty to name it automatically'
                    : 'Leave empty to use: $autoName',
                isDense: true,
              ),
            ),
            const SizedBox(height: 22),
            _sectionTitle('Log an exercise'),
            const SizedBox(height: 10),
            if (currentExercise == null)
              OutlinedButton.icon(
                onPressed: pickExercise,
                icon: const Icon(Icons.add_circle_outline, color: AppColors.lime),
                label: const Text('Choose exercise'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  side: BorderSide(color: AppColors.lime.withAlpha(120)),
                ),
              )
            else
              _buildEditor(),
            const SizedBox(height: 18),
            if (exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No exercises yet. Choose your first one above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              )
            else ...[
              _sectionTitle('This workout'),
              const SizedBox(height: 4),
              const Text(
                'Tap an exercise to log it again with the same values.',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 10),
            ],
            ...List.generate(exercises.length, (index) {
              final ex = exercises[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(18),
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: AppColors.lime,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.onLime,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(
                      ex.name,
                      style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${ex.sets} sets × ${ex.reps} reps · ${ex.weight} kg',
                      style: const TextStyle(color: AppColors.muted),
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
                ),
              );
            }),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: finish,
                icon: const Icon(Icons.check_rounded),
                label: Text(
                  pastMode ? 'Save workout' : 'Finish workout',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeaderStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.muted, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w800),
        ),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

/// "Smart Coach" progressive overload suggestion with an Apply button.
class _CoachCard extends StatelessWidget {
  final WeightSuggestion suggestion;
  final bool applied;
  final VoidCallback onApply;

  const _CoachCard({
    required this.suggestion,
    required this.applied,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: BoxDecoration(
        color: AppColors.lime.withAlpha(24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lime.withAlpha(90)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.lime),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach: try ${formatKg(suggestion.weight)} kg × ${suggestion.reps} today',
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  suggestion.reason,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          applied
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.check_circle, color: AppColors.lime),
                )
              : TextButton(onPressed: onApply, child: const Text('Apply')),
        ],
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
        style: const TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w900),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.cardHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          Row(
            children: [
              IconButton(
                onPressed: onMinus,
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.lime),
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
                icon: const Icon(Icons.add_circle, color: AppColors.lime),
                tooltip: 'More',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
