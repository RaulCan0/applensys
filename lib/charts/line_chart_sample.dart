
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class LineChartSample extends StatelessWidget {
  final List<FlSpot> spots;

  const LineChartSample({super.key, required this.spots});

  @override
  Widget build(BuildContext context) {
    return LineChart(LineChartData(
      lineBarsData: [
        LineChartBarData(spots: spots, isCurved: true, barWidth: 2, dotData: FlDotData(show: true)),
      ],
      titlesData: FlTitlesData(show: true),
    ));
  }
}
