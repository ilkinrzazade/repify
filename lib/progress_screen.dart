import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  // Sample data: weight (kg) per week. Replaced by real API data in Iteration 2.
  final Map<String, List<double>> data = const {
    'Bench Press': [60, 65, 70, 72, 78, 85],
    'Squat': [80, 85, 90, 95, 100, 110],
    'Deadlift': [100, 105, 110, 115, 125, 130],
    'Overhead Press': [30, 32.5, 35, 37.5, 40, 42.5],
  };

  String selected = 'Bench Press';

  String formatKg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final values = data[selected]!;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final first = values.first;
    final last = values.last;
    final diff = last - first;
    final percent = diff / first * 100;

    final minY = ((minV - 5) / 10).floor() * 10.0;
    final maxY = ((maxV + 5) / 10).ceil() * 10.0;
    final interval = (maxY - minY) <= 60 ? 10.0 : 20.0;

    final spots = [
      for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

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
            children: data.keys.map((name) {
              return ChoiceChip(
                label: Text(name),
                selected: selected == name,
                onSelected: (_) => setState(() => selected = name),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Text(
            '$selected: weight over 6 weeks (kg)',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: (values.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: interval,
                      getTitlesWidget: (value, meta) => Text(
                        value.toStringAsFixed(0),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Wk ${value.toInt() + 1}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withAlpha(40),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _SummaryCard(label: 'Start', value: '${formatKg(first)} kg')),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'Now', value: '${formatKg(last)} kg')),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  label: 'Change',
                  value: '+${formatKg(diff)} kg',
                  valueColor: Colors.green,
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
                  const Icon(Icons.trending_up, color: Colors.green, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You increased your $selected by ${formatKg(diff)} kg '
                      '(${percent.toStringAsFixed(0)}%) over 6 weeks!',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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