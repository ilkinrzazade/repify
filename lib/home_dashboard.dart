import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'coach.dart';
import 'health_cards.dart';
import 'workout_card.dart';
import 'workout_store.dart';

class HomeDashboard extends StatelessWidget {
  final VoidCallback onStartWorkout;
  final VoidCallback onSeeAll;
  final VoidCallback onScanEquipment;
  final VoidCallback onOpenMenu;
  final VoidCallback onOpenCoach;
  final Widget syncButton;

  const HomeDashboard({
    super.key,
    required this.onStartWorkout,
    required this.onSeeAll,
    required this.onScanEquipment,
    required this.onOpenMenu,
    required this.onOpenCoach,
    required this.syncButton,
  });

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkoutStore.instance,
      builder: (context, _) {
        final workouts = WorkoutStore.instance.workouts;
        final recent = workouts.take(3).toList();
        final recovery = muscleRecovery(workouts);
        final focus = suggestedFocus(recovery);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // Header: menu, greeting, sync.
            Row(
              children: [
                _RoundIconButton(icon: Icons.menu, onTap: onOpenMenu),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: const TextStyle(color: AppColors.muted, fontSize: 14),
                      ),
                      const Text(
                        'Ilkin 👋',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                syncButton,
              ],
            ),
            const SizedBox(height: 22),

            // Neon hero card: today's suggestion + start button.
            Container(
              padding: const EdgeInsets.all(20),
              decoration: limeCardDecoration(radius: 28),
              child: Stack(
                children: [
                  Positioned(
                    right: -6,
                    top: -6,
                    child: Icon(
                      Icons.fitness_center,
                      size: 96,
                      color: AppColors.onLime.withAlpha(30),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.onLime,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_awesome, size: 14, color: AppColors.lime),
                            SizedBox(width: 6),
                            Text(
                              'Smart coach',
                              style: TextStyle(
                                color: AppColors.lime,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        focus == null ? 'Rest day' : 'Today: $focus',
                        style: const TextStyle(
                          color: AppColors.onLime,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        focus == null
                            ? 'All muscles are still recovering. Light cardio or rest.'
                            : '$focus is fully recovered. Time to train it.',
                        style: TextStyle(color: AppColors.onLime.withAlpha(180), fontSize: 14),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: onStartWorkout,
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start new workout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.onLime,
                            foregroundColor: AppColors.lime,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Steps, calories and heart rate from Health Connect.
            const HealthPanel(),
            const SizedBox(height: 16),

            // AI scanner.
            _ActionCard(
              icon: Icons.photo_camera_outlined,
              title: 'Scan gym equipment',
              subtitle: 'AI shows the exercises you can do with it',
              onTap: onScanEquipment,
            ),
            const SizedBox(height: 12),

            // AI coach chat.
            _ActionCard(
              icon: Icons.auto_awesome,
              title: 'Ask your AI coach',
              subtitle: 'Personal advice based on your workouts',
              onTap: onOpenCoach,
            ),
            const SizedBox(height: 22),

            // Muscle recovery.
            _RecoveryPanel(statuses: recovery),
            const SizedBox(height: 24),

            // Recent workouts.
            Row(
              children: [
                const Expanded(child: _SectionTitle('Recent workouts')),
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 6),
            if (recent.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No workouts yet. Tap "Start new workout"!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.muted),
                ),
              ),
            ...recent.map((w) => WorkoutCard(workout: w)),
          ],
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(icon, color: AppColors.text, size: 22),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.lime.withAlpha(90)),
          ),
          child: Row(
            children: [
              IconBadge(icon, size: 48, filled: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.lime),
            ],
          ),
        ),
      ),
    );
  }
}

enum _Recovery { ready, recovering, never }

extension on MuscleStatus {
  _Recovery get state =>
      !trained ? _Recovery.never : (ready ? _Recovery.ready : _Recovery.recovering);
}

Color _recoveryColor(_Recovery state) {
  switch (state) {
    case _Recovery.ready:
      return AppColors.lime;
    case _Recovery.recovering:
      return AppColors.warning;
    case _Recovery.never:
      return const Color(0xFFB8BCC4);
  }
}

/// Muscle groups as tiles: status, last trained and a recovery bar.
class _RecoveryPanel extends StatelessWidget {
  final List<MuscleStatus> statuses;

  const _RecoveryPanel({required this.statuses});

  @override
  Widget build(BuildContext context) {
    final readyCount = statuses.where((s) => s.state == _Recovery.ready).length;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(Icons.healing, size: 36),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Muscle recovery',
                  style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                '$readyCount/${statuses.length} ready',
                style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'A muscle needs about 48 hours of rest after training.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _Legend(state: _Recovery.ready, text: 'Ready'),
              _Legend(state: _Recovery.recovering, text: 'Recovering'),
              _Legend(state: _Recovery.never, text: 'Not trained yet'),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.75,
            children: statuses.map((s) => _RecoveryTile(status: s)).toList(),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final _Recovery state;
  final String text;

  const _Legend({required this.state, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: _recoveryColor(state), shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.text, fontSize: 12)),
      ],
    );
  }
}

class _RecoveryTile extends StatelessWidget {
  final MuscleStatus status;

  const _RecoveryTile({required this.status});

  @override
  Widget build(BuildContext context) {
    final state = status.state;
    final color = _recoveryColor(state);
    final String statusText;
    final IconData icon;
    final double progress;
    switch (state) {
      case _Recovery.ready:
        statusText = 'Ready to train';
        icon = Icons.check_circle;
        progress = 1;
      case _Recovery.recovering:
        statusText = 'Recovering';
        icon = Icons.hourglass_bottom;
        progress = ((status.daysSince ?? 0) + 0.5) / recoveryDays;
      case _Recovery.never:
        statusText = 'Not trained yet';
        icon = Icons.remove_circle_outline;
        progress = 0;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withAlpha(140)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  status.group,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            statusText,
            style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            status.trained ? 'Last: ${status.label}' : 'No sessions yet',
            style: const TextStyle(color: Color(0xFFB8BCC4), fontSize: 11),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0).toDouble(),
              minHeight: 5,
              color: color,
              backgroundColor: AppColors.cardHigh,
            ),
          ),
        ],
      ),
    );
  }
}
