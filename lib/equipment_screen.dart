import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'active_workout_screen.dart';
import 'api_client.dart';
import 'app_theme.dart';
import 'equipment_guide.dart';
import 'exercise_library.dart';
import 'exercise_overview_screen.dart';

/// Take a photo of gym equipment: the AI on the server says what it is
/// and which exercises you can do with it. The offline guide below always works.
class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final ImagePicker picker = ImagePicker();
  Uint8List? photo;
  bool analyzing = false;
  EquipmentResult? result;
  String? error;

  Future<void> scan(ImageSource source) async {
    XFile? file;
    try {
      file = await picker.pickImage(source: source, maxWidth: 1280, imageQuality: 80);
    } catch (e) {
      setState(() => error = 'Could not open the ${source == ImageSource.camera ? 'camera' : 'gallery'}.');
      return;
    }
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      photo = bytes;
      analyzing = true;
      result = null;
      error = null;
    });
    try {
      final found = await ApiClient.instance.recognizeEquipment(bytes);
      if (!mounted) return;
      setState(() => result = found);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = e is ApiException ? e.message : 'Something went wrong: $e');
    } finally {
      if (mounted) setState(() => analyzing = false);
    }
  }

  void startWorkout(String exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ActiveWorkoutScreen(initialExercise: exercise)),
    );
  }

  void openOverview(String exercise) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ExerciseOverviewScreen(exercise: exercise)),
    );
  }

  Widget exerciseTile(String name) {
    final tip = tipFor(name);
    final images = exerciseImageUrls(name);
    return ListTile(
      onTap: () => openOverview(name),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 48,
          height: 48,
          color: Colors.white,
          child: images.isEmpty
              ? const Icon(Icons.fitness_center, color: Colors.grey)
              : Image.network(
                  images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      const Icon(Icons.fitness_center, color: Colors.grey),
                ),
        ),
      ),
      title: Text(name),
      subtitle: tip == null ? null : Text(tip, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: TextButton.icon(
        onPressed: () => startWorkout(name),
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start'),
      ),
    );
  }

  Widget buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.lime.withAlpha(110)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.lime),
              SizedBox(width: 8),
              Text(
                'AI Equipment Scanner',
                style: TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Take a photo of any gym machine. The AI tells you what it is, '
            'which muscles it trains and which exercises you can do.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: analyzing ? null : () => scan(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Camera'),

                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: analyzing ? null : () => scan(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),

                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildResult(EquipmentResult found) {
    if (found.isUnknown) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.search_off),
          title: Text('No gym equipment found'),
          subtitle: Text('Try another photo, or choose the equipment below.'),
        ),
      );
    }
    final guide = findEquipment(found.equipment);
    final exercises = found.exercises.isNotEmpty ? found.exercises : (guide?.exercises ?? const []);
    final percent = (found.confidence * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(guide?.icon ?? Icons.fitness_center,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      found.equipment,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Chip(label: Text('$percent% sure')),
                ],
              ),
            ),
            if (found.muscles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: found.muscles
                      .map((m) => Chip(
                            label: Text(m),
                            visualDensity: VisualDensity.compact,
                            avatar: const Icon(Icons.bolt, size: 16),
                          ))
                      .toList(),
                ),
              ),
            if (found.tip.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(found.tip)),
                  ],
                ),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Text(
                'EXERCISES YOU CAN DO',
                style: TextStyle(fontSize: 12, color: Colors.grey, letterSpacing: 1.2,
                    fontWeight: FontWeight.bold),
              ),
            ),
            ...exercises.map(exerciseTile),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPhoto = photo;
    final found = result;
    final problem = error;

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          buildHeader(context),
          if (currentPhoto != null) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(currentPhoto, height: 200, fit: BoxFit.cover),
            ),
          ],
          if (analyzing)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Analyzing the photo with AI...'),
                ],
              ),
            ),
          if (problem != null) ...[
            const SizedBox(height: 16),
            Card(
              color: AppColors.danger.withAlpha(30),
              child: ListTile(
                leading: const Icon(Icons.error_outline, color: AppColors.danger),
                title: Text(problem),
                subtitle: const Text('You can still choose the equipment yourself below.'),
              ),
            ),
          ],
          if (found != null) ...[
            const SizedBox(height: 16),
            buildResult(found),
          ],
          const SizedBox(height: 24),
          const Text(
            'Equipment guide',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'No photo? Choose the equipment yourself.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...equipmentGuide.map(
            (equipment) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                shape: const Border(),
                collapsedShape: const Border(),
                leading: Icon(equipment.icon),
                title: Text(equipment.name),
                subtitle: Text(equipment.muscles.join(' · ')),
                children: equipment.exercises.map(exerciseTile).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
