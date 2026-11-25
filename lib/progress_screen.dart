import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'achievements.dart';
import 'app_theme.dart';
import 'workout_stats.dart';
import 'workout_store.dart';

const Color _violet = Color(0xFF9B8CFF);

/// Overview (week / month), achievements, personal records and the
/// strength chart (line or bar), all built from the user's real data.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _RecordInfo {
  final String exercise;
  final double best;
  final DateTime date;
  final double gain;

  const _RecordInfo(this.exercise, this.best, this.date, this.gain);
}

class _ProgressScreenState extends State<ProgressScreen> {
  String? selected;
  bool monthView = false;
  bool showVolume = true;
  bool barChart = false;

  List<_RecordInfo> _records(List<Workout> workouts, List<String> exercises) {
    final result = <_RecordInfo>[];
    for (final name in exercises) {
      final points = progressFor(workouts, name);
      if (points.isEmpty) continue;
      var best = points.first;
      for (final p in points) {
        if (p.weight >= best.weight) best = p;
      }
      result.add(_RecordInfo(name, best.weight, best.date, best.weight - points.first.weight));
    }
    result.sort((a, b) => b.best.compareTo(a.best));
    return result;
  }

  Widget _title(String text, {IconData? icon, Color? iconColor, Widget? trailing}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? AppColors.lime),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.text, fontSize: 18, fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  BoxDecoration get _cardDecoration => BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: WorkoutStore.instance,
      builder: (context, _) {
        final workouts = WorkoutStore.instance.workouts;
        final exercises = trackedExercises(workouts).take(8).toList();

        if (workouts.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No data yet. Finish a workout to see your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ),
          );
        }

        final now = DateTime.now();
        final buckets = monthView
            ? recentWeekBuckets(workouts, now: now)
            : thisWeekBuckets(workouts, now: now);
        final monday = mondayOf(now);
        final sunday = DateTime(monday.year, monday.month, monday.day + 6);
        final rangeLabel = monthView
            ? 'Last 5 weeks'
            : '${shortDate(monday)} – ${shortDate(sunday)}';
        final periodVolume = buckets.fold<double>(0, (s, b) => s + b.volume);
        final periodMinutes = buckets.fold<int>(0, (s, b) => s + b.minutes);
        final periodWorkouts = buckets.fold<int>(0, (s, b) => s + b.workouts);

        final badges = achievements(workouts, now: now);
        final records = _records(workouts, exercises).take(6).toList();

        String? current;
        List<ProgressPoint> points = const [];
        if (exercises.isNotEmpty) {
          current = exercises.firstWhere(
            (e) => normalizeExerciseName(e) == normalizeExerciseName(selected ?? ''),
            orElse: () => exercises.first,
          );
          points = progressFor(workouts, current);
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          children: [
            _PillToggle(
              options: const ['Week', 'Month'],
              selectedIndex: monthView ? 1 : 0,
              onChanged: (i) => setState(() => monthView = i == 1),
            ),
            const SizedBox(height: 18),

            // Overview.
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              decoration: _cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _title(
                    monthView ? 'Monthly overview' : 'This week overview',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardHigh,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        rangeLabel,
                        style: const TextStyle(color: AppColors.text, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _MiniStat(value: '$periodWorkouts', label: 'Workouts')),
                      Expanded(child: _MiniStat(value: '${periodMinutes}m', label: 'Time')),
                      Expanded(child: _MiniStat(value: compactNumber(periodVolume), label: 'kg lifted')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildOverviewChart(buckets),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _MetricChip(
                        color: AppColors.lime,
                        text: 'Weight lifted (kg)',
                        selected: showVolume,
                        onTap: () => setState(() => showVolume = true),
                      ),
                      _MetricChip(
                        color: _violet,
                        text: 'Training time (min)',
                        selected: !showVolume,
                        onTap: () => setState(() => showVolume = false),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),

            // Achievements.
            _title(
              'Achievements',
              icon: Icons.military_tech,
              trailing: Text(
                '${badges.where((b) => b.unlocked).length}/${badges.length} unlocked',
                style: const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 214,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: badges.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _AchievementCard(achievement: badges[index]),
              ),
            ),
            const SizedBox(height: 26),

            // Personal records.
            if (records.isNotEmpty) ...[
              _title('Personal records', icon: Icons.emoji_events, iconColor: AppColors.gold),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.35,
                children: [
                  for (var i = 0; i < records.length; i++)
                    _RecordCard(record: records[i], highlight: i == 0),
                ],
              ),
              const SizedBox(height: 26),
            ],

            // Strength progress.
            if (current != null) ...[
              _title(
                'Strength progress',
                icon: Icons.trending_up,
                trailing: _PillToggle(
                  compact: true,
                  options: const ['Line', 'Bar'],
                  icons: const [Icons.show_chart, Icons.bar_chart],
                  selectedIndex: barChart ? 1 : 0,
                  onChanged: (i) => setState(() => barChart = i == 1),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final name = exercises[index];
                    return ChoiceChip(
                      label: Text(name),
                      showCheckmark: false,
                      selected: name == current,
                      onSelected: (_) => setState(() => selected = name),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 18, 18, 10),
                decoration: _cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, bottom: 14),
                      child: Text(
                        '$current · best weight per workout (kg)',
                        style: const TextStyle(color: AppColors.muted, fontSize: 13),
                      ),
                    ),
                    if (points.length >= 2)
                      (barChart ? _buildStrengthBars(points) : _buildStrengthLine(points))
                    else
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Log this exercise again to see a trend.',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ),
                  ],
                ),
              ),
              if (points.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildInsight(current, points),
              ],
            ],
          ],
        );
      },
    );
  }

  // ---------- Charts ----------

  Widget _bottomLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      );

  FlGridData _grid(double interval) => FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: interval,
        getDrawingHorizontalLine: (_) =>
            const FlLine(color: AppColors.border, strokeWidth: 1, dashArray: [4, 4]),
      );

  Widget _buildOverviewChart(List<PeriodBucket> buckets) {
    final color = showVolume ? AppColors.lime : _violet;
    final values = buckets.map((b) => showVolume ? b.volume : b.minutes.toDouble()).toList();
    final maxValue = values.fold<double>(0, (a, b) => math.max(a, b));
    final maxY = maxValue <= 0 ? (showVolume ? 1000.0 : 60.0) : maxValue * 1.25;
    final todayIndex = monthView ? buckets.length - 1 : DateTime.now().weekday - 1;

    return SizedBox(
      height: 190,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: _grid(maxY / 4),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardHigh,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                showVolume ? '${compactNumber(rod.toY)} kg' : '${rod.toY.round()} min',
                TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 38,
                interval: maxY / 4,
                getTitlesWidget: (value, meta) => Text(
                  compactNumber(value),
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= buckets.length) return const SizedBox.shrink();
                  return _bottomLabel(buckets[i].label);
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: monthView ? 26 : 16,
                    color: i == todayIndex ? color : color.withAlpha(150),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppColors.cardHigh,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  ({double minY, double maxY, double interval, int labelStep}) _strengthScale(
      List<ProgressPoint> points) {
    final weights = points.map((p) => p.weight).toList();
    final minV = weights.reduce((a, b) => math.min(a, b));
    final maxV = weights.reduce((a, b) => math.max(a, b));
    var minY = ((minV - 5) / 10).floor() * 10.0;
    var maxY = ((maxV + 5) / 10).ceil() * 10.0;
    if (minY < 0) minY = 0;
    if (maxY - minY < 20) maxY = minY + 20;
    final interval = (maxY - minY) <= 60 ? 10.0 : 20.0;
    final labelStep = math.max(1, (points.length / 5).ceil());
    return (minY: minY, maxY: maxY, interval: interval, labelStep: labelStep);
  }

  FlTitlesData _strengthTitles(List<ProgressPoint> points, double interval, int labelStep) {
    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: interval,
          getTitlesWidget: (value, meta) => Text(
            value.toStringAsFixed(0),
            style: const TextStyle(fontSize: 11, color: AppColors.muted),
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
            if ((value - i).abs() > 0.01 || i < 0 || i >= points.length || i % labelStep != 0) {
              return const SizedBox.shrink();
            }
            return _bottomLabel(shortDate(points[i].date));
          },
        ),
      ),
    );
  }

  Widget _buildStrengthLine(List<ProgressPoint> points) {
    final scale = _strengthScale(points);
    final spots = [
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].weight),
    ];
    return SizedBox(
      height: 230,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: scale.minY,
          maxY: scale.maxY,
          gridData: _grid(scale.interval),
          borderData: FlBorderData(show: false),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardHigh,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${formatKg(s.y)} kg',
                        const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
                      ))
                  .toList(),
            ),
          ),
          titlesData: _strengthTitles(points, scale.interval, scale.labelStep),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              preventCurveOverShooting: true,
              color: AppColors.lime,
              barWidth: 4,
              shadow: Shadow(color: AppColors.lime.withAlpha(120), blurRadius: 12),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: index == spots.length - 1 ? 6 : 3.5,
                  color: AppColors.lime,
                  strokeWidth: 2,
                  strokeColor: AppColors.background,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.lime.withAlpha(90), AppColors.lime.withAlpha(0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthBars(List<ProgressPoint> points) {
    final scale = _strengthScale(points);
    final best = points.map((p) => p.weight).reduce((a, b) => math.max(a, b));
    return SizedBox(
      height: 230,
      child: BarChart(
        BarChartData(
          minY: scale.minY,
          maxY: scale.maxY,
          alignment: BarChartAlignment.spaceAround,
          gridData: _grid(scale.interval),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.cardHigh,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${formatKg(rod.toY)} kg',
                const TextStyle(color: AppColors.lime, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          titlesData: _strengthTitles(points, scale.interval, scale.labelStep),
          barGroups: [
            for (var i = 0; i < points.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    fromY: scale.minY,
                    toY: points[i].weight,
                    width: math.min(22.0, 160.0 / points.length),
                    color: points[i].weight == best
                        ? AppColors.lime
                        : AppColors.lime.withAlpha(140),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsight(String exercise, List<ProgressPoint> points) {
    final first = points.first.weight;
    final last = points.last.weight;
    final diff = last - first;

    final String message;
    final IconData icon;
    final Color color;
    if (points.length < 2) {
      message = 'Only one session so far. Log $exercise again to see a trend.';
      icon = Icons.info_outline;
      color = AppColors.muted;
    } else if (diff > 0) {
      final percent = first > 0 ? (diff / first * 100).toStringAsFixed(0) : '0';
      message = 'You increased your $exercise by ${formatKg(diff)} kg '
          '($percent%) since ${shortDate(points.first.date)}!';
      icon = Icons.trending_up;
      color = AppColors.lime;
    } else if (diff == 0) {
      message = 'Same weight as your first session. Time to add a little more?';
      icon = Icons.trending_flat;
      color = AppColors.warning;
    } else {
      message = 'Your last session was lighter than the first one. Keep going!';
      icon = Icons.trending_down;
      color = AppColors.danger;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: AppColors.text))),
        ],
      ),
    );
  }
}

// ---------- Small widgets ----------

/// Pill-shaped switch like "Week | Month".
class _PillToggle extends StatelessWidget {
  final List<String> options;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool compact;

  const _PillToggle({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          for (var i = 0; i < options.length; i++)
            _segment(i, compact ? null : 1),
        ],
      ),
    );
  }

  Widget _segment(int i, int? flex) {
    final active = i == selectedIndex;
    final child = GestureDetector(
      onTap: () => onChanged(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: compact ? 6 : 10, horizontal: compact ? 12 : 8),
        decoration: BoxDecoration(
          color: active ? AppColors.lime.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: active ? AppColors.lime : Colors.transparent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icons != null) ...[
              Icon(icons![i], size: 16, color: active ? AppColors.lime : AppColors.muted),
              const SizedBox(width: 4),
            ],
            Text(
              options[i],
              style: TextStyle(
                color: active ? AppColors.lime : AppColors.muted,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 12 : 14,
              ),
            ),
          ],
        ),
      ),
    );
    return flex == null ? child : Expanded(flex: flex, child: child);
  }
}

class _MetricChip extends StatelessWidget {
  final Color color;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _MetricChip({
    required this.color,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                color: selected ? AppColors.text : AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String value;
  final String label;

  const _MiniStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11)),
      ],
    );
  }
}

/// Hexagon badge with a neon glow when unlocked.
class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    final color = unlocked ? AppColors.lime : AppColors.muted;
    return Container(
      width: 152,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: unlocked ? AppColors.lime.withAlpha(110) : AppColors.border),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 84,
            height: 92,
            child: CustomPaint(
              painter: _HexagonPainter(color: color, glow: unlocked),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(achievement.icon, size: 16, color: unlocked ? AppColors.onLime : AppColors.muted),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        achievement.badge,
                        style: TextStyle(
                          color: unlocked ? AppColors.onLime : AppColors.muted,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unlocked ? AppColors.text : AppColors.muted,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              achievement.description,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ),
          if (!unlocked)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: achievement.progress,
                minHeight: 5,
                color: AppColors.lime,
                backgroundColor: AppColors.cardHigh,
              ),
            ),
        ],
      ),
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color color;
  final bool glow;

  _HexagonPainter({required this.color, required this.glow});

  Path _hexagon(Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = math.min(size.width, size.height) / 2 - 6;
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 2;
      final point = Offset(cx + r * math.cos(angle), cy + r * math.sin(angle));
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _hexagon(size);
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: glow
              ? [AppColors.lime, AppColors.limeDark]
              : [AppColors.cardHigh, AppColors.card],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = glow ? AppColors.text.withAlpha(200) : AppColors.border,
    );
  }

  @override
  bool shouldRepaint(covariant _HexagonPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.glow != glow;
}

class _RecordCard extends StatelessWidget {
  final _RecordInfo record;
  final bool highlight;

  const _RecordCard({required this.record, required this.highlight});

  @override
  Widget build(BuildContext context) {
    final fg = highlight ? AppColors.onLime : AppColors.text;
    final sub = highlight ? AppColors.onLime.withAlpha(170) : AppColors.muted;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: highlight
          ? limeCardDecoration(radius: 22)
          : BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 22,
                color: highlight ? AppColors.onLime : AppColors.gold,
              ),
              const Spacer(),
              if (record.gain > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: highlight ? AppColors.onLime : AppColors.lime.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+${formatKg(record.gain)} kg',
                    style: const TextStyle(
                      color: AppColors.lime,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            record.exercise,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: sub, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${formatKg(record.best)} kg',
              style: TextStyle(color: fg, fontSize: 24, fontWeight: FontWeight.w900),
            ),
          ),
          Text(shortDate(record.date), style: TextStyle(color: sub, fontSize: 11)),
        ],
      ),
    );
  }
}
