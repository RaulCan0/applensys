import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class BehaviorsScrollChart extends StatelessWidget {
  final List<double> data;
  final String title;

  const BehaviorsScrollChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries
        .map((e) => ScatterSpot(e.key.toDouble(), e.value))
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ScatterChart(
        ScatterChartData(
          scatterSpots: spots,
          minX: 0,
          maxX: data.length.toDouble(),
          minY: 0,
          maxY: data.reduce((a, b) => a > b ? a : b) + 1,
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) => Text('B${value.toInt() + 1}'),
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
          ),
        ),
      ),
    );
  }
}
