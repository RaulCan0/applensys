
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ScatterData {
  final double x;
  final double y;
  final double radius;
  final Color color;

  ScatterData({required this.x, required this.y, required this.radius, required this.color});
}

class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final String title;
  final double minValue;
  final double maxValue;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    required this.title,
    this.minValue = 0,
    this.maxValue = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.3,
              child: ScatterChart(
                ScatterChartData(
                  minX: minValue,
                  maxX: maxValue,
                  minY: minValue,
                  maxY: maxValue,
                  scatterSpots: data.map((d) => ScatterSpot(d.x, d.y, radius: d.radius, color: d.color)).toList(),
                  borderData: FlBorderData(show: true),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
