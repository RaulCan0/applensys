import 'package:applensys/models/level_averages.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GroupedBarChart extends StatelessWidget {
  final List<LevelAverages> data;
  final String title;
  final double minY;
  final double maxY;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(show: true),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.black26, width: 1)),
        barGroups: data.isEmpty
            ? []
            : data.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(toY: e.ejecutivo, color: Colors.blue),
                    BarChartRodData(toY: e.gerente, color: Colors.green),
                    BarChartRodData(toY: e.miembro, color: Colors.orange),
                  ],
                );
              }).toList(),
      ),
    );
  }
}
