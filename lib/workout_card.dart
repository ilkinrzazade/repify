import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'workout_detail_screen.dart';
import 'workout_store.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;

  const WorkoutCard({super.key, required this.workout});

  IconData get _icon {
    final name = workout.name.toLowerCase();
    if (name.contains('leg')) return Icons.directions_run;
    if (name.contains('pull') || name.contains('back')) return Icons.rowing;
    if (name.contains('core')) return Icons.self_improvement;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => WorkoutDetailScreen(workout: workout)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                IconBadge(_icon, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              workout.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (!workout.isSynced) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.cloud_off, size: 14, color: AppColors.warning),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workout.formattedDate} · ${workout.exercises.length} exercises',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                      if (workout.hasDuration) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _Pill(icon: Icons.timer_outlined, text: workout.formattedDuration),
                            const SizedBox(width: 6),
                            _Pill(icon: Icons.bolt, text: workout.formattedVolume),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cardHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.lime),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: AppColors.text, fontSize: 12)),
        ],
      ),
    );
  }
}
