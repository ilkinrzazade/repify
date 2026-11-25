import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'exercise_catalog.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

/// Bottom sheet for choosing an exercise: recent ones, the catalog by
/// muscle group, a search box, and the option to add a custom exercise.
/// Returns the chosen name with Navigator.pop.
class ExercisePickerSheet extends StatefulWidget {
  const ExercisePickerSheet({super.key});

  @override
  State<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<ExercisePickerSheet> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Widget _header(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
          letterSpacing: 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _tile(String name, {IconData? icon}) {
    return ListTile(
      leading: icon == null ? null : Icon(icon, size: 20),
      title: Text(name),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.pop(context, name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final recent = trackedExercises(WorkoutStore.instance.workouts).take(6).toList();
    final q = normalizeExerciseName(query);
    bool matches(String name) => q.isEmpty || normalizeExerciseName(name).contains(q);

    final allNames = <String>{
      for (final list in exerciseCatalog.values)
        for (final name in list) normalizeExerciseName(name),
      for (final name in recent) normalizeExerciseName(name),
    };

    final children = <Widget>[];

    if (q.isNotEmpty && !allNames.contains(q)) {
      children.add(
        ListTile(
          leading: const Icon(Icons.add_circle_outline),
          title: Text('Add "${query.trim()}"'),
          subtitle: const Text('Custom exercise'),
          onTap: () => Navigator.pop(context, query.trim()),
        ),
      );
    }

    final recentMatches = recent.where(matches).toList();
    if (recentMatches.isNotEmpty) {
      children.add(_header('Recent'));
      children.addAll(recentMatches.map((n) => _tile(n, icon: Icons.history)));
    }

    for (final entry in exerciseCatalog.entries) {
      final items = entry.value.where(matches).toList();
      if (items.isEmpty) continue;
      children.add(_header(entry.key));
      children.addAll(items.map((n) => _tile(n)));
    }

    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final height = math.max(240.0, media.size.height * 0.8 - keyboard);

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                controller: searchController,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  hintText: 'Search or type a new exercise',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            Expanded(
              child: children.isEmpty
                  ? const Center(child: Text('No matches'))
                  : ListView(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
