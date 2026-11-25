import 'dart:async';

import 'package:flutter/material.dart';

import 'active_workout_screen.dart';
import 'app_theme.dart';
import 'equipment_guide.dart';
import 'exercise_catalog.dart';
import 'exercise_library.dart';
import 'video_tutorial_screen.dart';

/// How to do an exercise: animated start/end pictures, steps,
/// muscles, a technique tip and a link to a video tutorial.
class ExerciseOverviewScreen extends StatefulWidget {
  final String exercise;
  final bool showStartButton;

  const ExerciseOverviewScreen({
    super.key,
    required this.exercise,
    this.showStartButton = true,
  });

  @override
  State<ExerciseOverviewScreen> createState() => _ExerciseOverviewScreenState();
}

class _ExerciseOverviewScreenState extends State<ExerciseOverviewScreen> {
  late final Future<ExerciseDetails?> details =
      ExerciseLibrary.detailsFor(widget.exercise);

  void openVideo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoTutorialScreen(
          exercise: widget.exercise,
          url: videoTutorialUri(widget.exercise),
        ),
      ),
    );
  }

  void start() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveWorkoutScreen(initialExercise: widget.exercise),
      ),
    );
  }

  Widget sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );

  Widget chip(String text, {IconData? icon}) => Chip(
        label: Text(text),
        avatar: icon == null ? null : Icon(icon, size: 16),
        visualDensity: VisualDensity.compact,
      );

  String capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final tip = tipFor(widget.exercise);
    final group = muscleGroupOf(widget.exercise);
    final images = exerciseImageUrls(widget.exercise);

    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (images.isNotEmpty)
            _AnimatedExerciseImages(urls: images)
          else
            Container(
              height: 160,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.fitness_center, size: 64),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (group != null) chip(group, icon: Icons.bolt),
              FutureBuilder<ExerciseDetails?>(
                future: details,
                builder: (context, snapshot) {
                  final d = snapshot.data;
                  if (d?.level == null) return const SizedBox.shrink();
                  return chip(capitalize(d!.level!), icon: Icons.signal_cellular_alt);
                },
              ),
            ],
          ),
          if (tip != null) ...[
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.lightbulb_outline, color: Colors.amber),
                title: const Text('Coach tip'),
                subtitle: Text(tip),
              ),
            ),
          ],
          sectionTitle('How to do it'),
          FutureBuilder<ExerciseDetails?>(
            future: details,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                );
              }
              final d = snapshot.data;
              if (snapshot.hasError || d == null || d.instructions.isEmpty) {
                return const Text(
                  'Step-by-step instructions are not available right now. '
                  'Check the internet connection or watch the video below.',
                  style: TextStyle(color: Colors.grey),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < d.instructions.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontSize: 12, color: AppColors.onLime, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Text(d.instructions[i])),
                        ],
                      ),
                    ),
                  if (d.primaryMuscles.isNotEmpty || d.secondaryMuscles.isNotEmpty) ...[
                    sectionTitle('Muscles worked'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...d.primaryMuscles.map((m) => chip(capitalize(m), icon: Icons.star)),
                        ...d.secondaryMuscles.map((m) => chip(capitalize(m))),
                      ],
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: openVideo,
            icon: const Icon(Icons.play_circle_outline),
            label: const Text('Watch video tutorial'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (widget.showStartButton) ...[
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: start,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Start this exercise'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Pictures and steps: free-exercise-db (public domain).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

/// Shows the start and end position one after another, like a short animation.
class _AnimatedExerciseImages extends StatefulWidget {
  final List<String> urls;

  const _AnimatedExerciseImages({required this.urls});

  @override
  State<_AnimatedExerciseImages> createState() => _AnimatedExerciseImagesState();
}

class _AnimatedExerciseImagesState extends State<_AnimatedExerciseImages> {
  int index = 0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (widget.urls.length > 1) {
      timer = Timer.periodic(const Duration(milliseconds: 1100), (_) {
        setState(() => index = (index + 1) % widget.urls.length);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final url in widget.urls) {
      precacheImage(NetworkImage(url), context, onError: (_, __) {});
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.urls[index];
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 230,
        color: Colors.white,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.network(
                  url,
                  key: ValueKey(url),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (context, error, stack) => const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.image_not_supported_outlined, color: Colors.grey, size: 40),
                        SizedBox(height: 6),
                        Text('Picture not available', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  index == 0 ? 'Start position' : 'End position',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
