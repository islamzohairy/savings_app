import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class TrendChart extends StatelessWidget {
  const TrendChart({super.key, required this.data});
  final List<Map<String, dynamic>> data;

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[];
    final labels = <String>[];
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), (data[i]['net'] as int).toDouble()));
      labels.add(data[i]['month'] as String);
    }
    if (spots.isEmpty) return const SizedBox.shrink();
    final chartHeight = MediaQuery.of(context).size.height * 0.25;
    return SizedBox(
      height: chartHeight,
      child: BarChart(
        BarChartData(
          barGroups: spots.map((s) => BarChartGroupData(
            x: s.x.toInt(),
            barRods: [
              BarChartRodData(
                toY: s.y,
                color: s.y >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
                width: 20,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          )).toList(),
          alignment: BarChartAlignment.spaceAround,
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < labels.length) {
                    final parts = labels[idx].split('-');
                    return Text(parts.length > 1 ? parts[1] : labels[idx], style: Theme.of(context).textTheme.labelSmall);
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
        ),
      ),
    );
  }
}
