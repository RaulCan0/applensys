
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/level_averages.dart';

class LineChartSample extends StatelessWidget {
  final List<LevelAverages> data; // cada punto tiene: x, e, g, m
  final String title;
  final double minY;
  final double maxY;

  const LineChartSample({
    super.key,
    required this.data,
    required this.title,
    this.minY = 0,
    this.maxY = 5,
  });

  @override
  Widget build(BuildContext context) {
    List<FlSpot> eSpots = [];
    List<FlSpot> gSpots = [];
    List<FlSpot> mSpots = [];

    for (var i = 0; i < data.length; i++) {
      eSpots.add(FlSpot(i.toDouble(), data[i].ejecutivo));
      gSpots.add(FlSpot(i.toDouble(), data[i].gerente));
      mSpots.add(FlSpot(i.toDouble(), data[i].miembro));
    }

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  lineBarsData: [
                    LineChartBarData(spots: eSpots, color: Colors.blue, isCurved: true),
                    LineChartBarData(spots: gSpots, color: Colors.orange, isCurved: true),
                    LineChartBarData(spots: mSpots, color: Colors.green, isCurved: true),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
