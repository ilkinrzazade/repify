import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'health_screen.dart';
import 'health_service.dart';
import 'workout_store.dart';

const Color heartColor = Color(0xFFFF5C7A);
const Color calorieColor = Color(0xFFFFB547);
const Color trainingColor = Color(0xFF9B8CFF);

/// Home screen: daily rings (steps, calories, training) and heart rate.
class HealthPanel extends StatelessWidget {
  const HealthPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final service = HealthService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([service, WorkoutStore.instance]),
      builder: (context, _) {
        switch (service.status) {
          case HealthStatus.unavailable:
            return const SizedBox.shrink();
          case HealthStatus.connected:
            return Column(
              children: [
                _DailyProgressCard(service: service),
                const SizedBox(height: 12),
                _HeartRateCard(health: service.today),
              ],
            );
          default:
            return _ConnectCard(service: service);
        }
      },
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    );

class _ConnectCard extends StatelessWidget {
  final HealthService service;

  const _ConnectCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: heartColor.withAlpha(35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.favorite, color: heartColor),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Connect Health Connect',
                  style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Text(
                  'Steps, heart rate and calories from your phone and watch',
                  style: TextStyle(color: AppColors.muted, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HealthScreen()),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }
}

class _DailyProgressCard extends StatelessWidget {
  final HealthService service;

  const _DailyProgressCard({required this.service});

  @override
  Widget build(BuildContext context) {
    final health = service.today;
    final now = DateTime.now();
    final trainingMinutes = WorkoutStore.instance.workouts
        .where((w) => w.date.year == now.year && w.date.month == now.month && w.date.day == now.day)
        .fold<int>(0, (s, w) => s + w.duration.inMinutes);

    final rings = [
      _Ring(AppColors.lime, ringProgress(health.steps, stepGoal)),
      _Ring(calorieColor, ringProgress(health.activeCalories, calorieGoal)),
      _Ring(trainingColor, ringProgress(trainingMinutes, trainingGoalMinutes)),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daily progress',
                  style: TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              if (service.isLoading)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              else
                IconButton(
                  tooltip: 'Refresh from Health Connect',
                  onPressed: service.refresh,
                  icon: const Icon(Icons.sync, color: AppColors.muted, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: CustomPaint(painter: _RingsPainter(rings)),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _RingLegend(
                      color: AppColors.lime,
                      icon: Icons.directions_walk,
                      label: 'Steps',
                      value: '${health.steps}',
                      goal: '/$stepGoal',
                    ),
                    const SizedBox(height: 12),
                    _RingLegend(
                      color: calorieColor,
                      icon: Icons.local_fire_department,
                      label: 'Active calories',
                      value: '${health.activeCalories.round()}',
                      goal: '/$calorieGoal kcal',
                    ),
                    const SizedBox(height: 12),
                    _RingLegend(
                      color: trainingColor,
                      icon: Icons.fitness_center,
                      label: 'Training',
                      value: '$trainingMinutes',
                      goal: '/$trainingGoalMinutes min',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingLegend extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String value;
  final String goal;

  const _RingLegend({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.goal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(color: color.withAlpha(35), borderRadius: BorderRadius.circular(11)),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      TextSpan(
                        text: goal,
                        style: const TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Ring {
  final Color color;
  final double progress;

  const _Ring(this.color, this.progress);
}

/// Concentric activity rings, outer ring first.
class _RingsPainter extends CustomPainter {
  final List<_Ring> rings;

  _RingsPainter(this.rings);

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 11.0;
    const gap = 4.0;
    final center = size.center(Offset.zero);
    var radius = math.min(size.width, size.height) / 2 - stroke / 2;
    for (final ring in rings) {
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = ring.color.withAlpha(40),
      );
      if (ring.progress > 0) {
        canvas.drawArc(
          rect,
          -math.pi / 2,
          2 * math.pi * math.max(ring.progress, 0.02),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = ring.color,
        );
      }
      radius -= stroke + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _RingsPainter oldDelegate) => true;
}

class _HeartRateCard extends StatelessWidget {
  final DailyHealth health;

  const _HeartRateCard({required this.health});

  @override
  Widget build(BuildContext context) {
    final latest = health.latestBpm;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.favorite_border, color: heartColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Heart rate',
                style: TextStyle(color: AppColors.text, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (latest == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No heart rate data today. Wear your watch, or add demo data '
                'in Menu → Health Connect.',
                style: TextStyle(color: AppColors.muted),
              ),
            )
          else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${latest.round()}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 6, bottom: 6),
                  child: Text('BPM', style: TextStyle(color: heartColor, fontWeight: FontWeight.w700)),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'avg ${health.averageBpm!.round()}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                    Text(
                      'max ${health.maxBpm!.round()}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 46,
              width: double.infinity,
              child: CustomPaint(painter: _PulsePainter(health.heartRate)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Vertical bars like a pulse wave: one bar per heart rate sample.
class _PulsePainter extends CustomPainter {
  final List<HeartSample> samples;

  _PulsePainter(this.samples);

  @override
  void paint(Canvas canvas, Size size) {
    if (samples.isEmpty) return;
    // Show at most 40 bars: average neighbouring samples.
    final count = math.min(40, samples.length);
    final values = List<double>.generate(count, (i) {
      final from = (i * samples.length / count).floor();
      final to = math.max(from + 1, ((i + 1) * samples.length / count).floor());
      final slice = samples.sublist(from, to);
      return slice.fold<double>(0, (s, h) => s + h.bpm) / slice.length;
    });
    final low = values.reduce(math.min) - 10;
    final high = values.reduce(math.max);
    final slot = size.width / count;
    final barWidth = math.min(6.0, slot * 0.55);
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    for (var i = 0; i < count; i++) {
      final t = high - low <= 0 ? 0.5 : (values[i] - low) / (high - low);
      final h = math.max(6.0, size.height * t);
      final x = slot * i + slot / 2;
      final top = (size.height - h) / 2;
      paint.color = heartColor.withAlpha((110 + 145 * t).round().clamp(0, 255));
      canvas.drawLine(Offset(x, top + barWidth / 2), Offset(x, top + h - barWidth / 2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PulsePainter oldDelegate) => oldDelegate.samples != samples;
}
