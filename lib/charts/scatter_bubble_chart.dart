
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ScatterBubbleChart extends StatelessWidget {
  final Map<String, Map<String, int>> data;

  const ScatterBubbleChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = <ScatterSpot>[];
    int x = 0;

    data.forEach((dimension, niveles) {
      niveles.forEach((nivel, valor) {
        spots.add(ScatterSpot(x.toDouble(), valor.toDouble(), radius: 8, color: Colors.blue));
        x++;
      });
    });

    return ScatterChart(ScatterChartData(
      scatterSpots: spots,
      minX: 0,
      maxX: (spots.length + 1).toDouble(),
      minY: 0,
      maxY: 5,
      borderData: FlBorderData(show: false),
    ));
  }
}
