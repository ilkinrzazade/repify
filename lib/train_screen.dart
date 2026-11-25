import 'package:flutter/material.dart';

import 'active_workout_screen.dart';
import 'app_theme.dart';
import 'equipment_screen.dart';
import 'exercise_catalog.dart';

/// The "Train" tab: every way to start or log a workout in one place.
class TrainScreen extends StatelessWidget {
  final VoidCallback onOpenHistory;

  const TrainScreen({super.key, required this.onOpenHistory});

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Big neon card: live workout.
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () => _open(context, const ActiveWorkoutScreen()),
            child: Ink(
              padding: const EdgeInsets.all(22),
              decoration: limeCardDecoration(radius: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Live workout',
                          style: TextStyle(
                            color: AppColors.onLime,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Timer, smart coach and personal records while you train.',
                          style: TextStyle(color: AppColors.onLime.withAlpha(180)),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color: AppColors.onLime,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_arrow_rounded, color: AppColors.lime, size: 20),
                              SizedBox(width: 4),
                              Text(
                                'Start now',
                                style: TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: AppColors.onLime,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.timer_outlined, color: AppColors.lime, size: 38),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Bento tiles.
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.photo_camera_outlined,
                title: 'AI Scanner',
                subtitle: 'Photo of a machine',
                onTap: () => _open(context, const EquipmentScreen()),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                icon: Icons.menu_book_outlined,
                title: 'Exercise library',
                subtitle: '${exerciseCatalog.values.fold<int>(0, (n, l) => n + l.length)} exercises',
                onTap: () => _open(context, const EquipmentScreen()),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _Tile(
                icon: Icons.edit_calendar_outlined,
                title: 'Log past workout',
                subtitle: 'Forgot to track?',
                onTap: () => _open(context, const ActiveWorkoutScreen(pastMode: true)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Tile(
                icon: Icons.history,
                title: 'History',
                subtitle: 'All your sessions',
                onTap: onOpenHistory,
              ),
            ),
          ],
        ),
        const SizedBox(height: 26),

        const Text(
          'Quick start',
          style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text(
          'Start a live workout with a ready name.',
          style: TextStyle(color: AppColors.muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...presetWorkoutNames.map(
          (name) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: AppColors.border),
                ),
                leading: IconBadge(_iconFor(name), size: 40),
                title: Text(
                  name,
                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_descriptionFor(name), style: const TextStyle(color: AppColors.muted)),
                trailing: const Icon(Icons.play_circle_fill, color: AppColors.lime, size: 32),
                onTap: () => _open(context, ActiveWorkoutScreen(initialName: name)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(String name) {
    switch (name) {
      case 'Leg Day':
        return Icons.directions_run;
      case 'Pull Day':
        return Icons.rowing;
      case 'Full Body':
        return Icons.accessibility_new;
      default:
        return Icons.fitness_center;
    }
  }

  static String _descriptionFor(String name) {
    switch (name) {
      case 'Push Day':
        return 'Chest · Shoulders · Triceps';
      case 'Pull Day':
        return 'Back · Biceps';
      case 'Leg Day':
        return 'Quads · Hamstrings · Calves';
      case 'Upper Body':
        return 'Chest · Back · Arms';
      default:
        return 'Every muscle group';
    }
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          height: 132,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconBadge(icon, size: 42),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
