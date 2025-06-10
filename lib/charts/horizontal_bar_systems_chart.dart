import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String,double>> data;
  final String title;
  final double minX, maxX;
  final int minY, maxY;             // <-- nuevos campos

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    // … llenas chartData como antes …

    return Column(
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(minimum: minX, maximum: maxX),
            primaryYAxis: NumericAxis(
              minimum: minY.toDouble(),
              maximum: maxY.toDouble(),
              interval: ((maxY-minY)/5).ceilToDouble(),
            ),
            series: [ /* tus BarSeries */ ],
            legend: Legend(isVisible: true),
          ),
        ),
      ],
    );
  }
}
