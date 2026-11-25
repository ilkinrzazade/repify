import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'workout_stats.dart';
import 'workout_store.dart';

/// Line chart of the best weight per workout, built from the user's real data.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? selected;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkoutStore.instance,
      builder: (context, _) {
        final workouts = WorkoutStore.instance.workouts;
        final exercises = trackedExercises(workouts).take(8).toList();

        if (exercises.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No data yet. Finish a workout to see your progress.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final current = exercises.firstWhere(
          (e) => normalizeExerciseName(e) == normalizeExerciseName(selected ?? ''),
          orElse: () => exercises.first,
        );
        final points = progressFor(workouts, current);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Exercise',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercises.map((name) {
                  return ChoiceChip(
                    label: Text(name),
                    selected: name == current,
                    onSelected: (_) => setState(() => selected = name),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text(
                '$current: best weight per workout (kg)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (points.length >= 2) _buildChart(context, points),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildSummary(current, points),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart(BuildContext context, List<ProgressPoint> points) {
    final color = Theme.of(context).colorScheme.primary;
    final weights = points.map((p) => p.weight).toList();
    final minV = weights.reduce(math.min);
    final maxV = weights.reduce(math.max);

    var minY = ((minV - 5) / 10).floor() * 10.0;
    var maxY = ((maxV + 5) / 10).ceil() * 10.0;
    if (minY < 0) minY = 0;
    if (maxY - minY < 20) maxY = minY + 20;
    final yInterval = (maxY - minY) <= 60 ? 10.0 : 20.0;
    final labelStep = math.max(1, (points.length / 5).ceil());

    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].weight),
    ];

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if ((value - i).abs() > 0.01 ||
                      i < 0 ||
                      i >= points.length ||
                      i % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      shortDate(points[i].date),
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: color,
              barWidth: 4,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: true, color: color.withAlpha(40)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(String exercise, List<ProgressPoint> points) {
    final first = points.first.weight;
    final last = points.last.weight;
    final best = points.map((p) => p.weight).reduce(math.max);
    final diff = last - first;
    final changeText = diff > 0 ? '+${formatKg(diff)} kg' : '${formatKg(diff)} kg';
    final changeColor = diff > 0 ? Colors.green : (diff < 0 ? Colors.red : null);

    final String message;
    final IconData icon;
    final Color iconColor;
    if (points.length < 2) {
      message = 'Only one session so far (${formatKg(first)} kg on '
          '${shortDate(points.first.date)}). Log $exercise again to see a trend.';
      icon = Icons.info_outline;
      iconColor = Colors.grey;
    } else if (diff > 0) {
      final percent = first > 0 ? (diff / first * 100).toStringAsFixed(0) : '0';
      message = 'You increased your $exercise by ${formatKg(diff)} kg '
          '($percent%) since ${shortDate(points.first.date)}!';
      icon = Icons.trending_up;
      iconColor = Colors.green;
    } else if (diff == 0) {
      message = 'Same weight as your first session. Time to add a little more?';
      icon = Icons.trending_flat;
      iconColor = Colors.orange;
    } else {
      message = 'Your last session was lighter than the first one. Keep going!';
      icon = Icons.trending_down;
      iconColor = Colors.red;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _SummaryCard(label: 'Start', value: '${formatKg(first)} kg')),
            const SizedBox(width: 10),
            Expanded(child: _SummaryCard(label: 'Best (PR)', value: '${formatKg(best)} kg')),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryCard(
                label: 'Change',
                value: changeText,
                valueColor: changeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
