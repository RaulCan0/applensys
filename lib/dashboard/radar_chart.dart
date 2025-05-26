// filepath: lib/charts/radar_chart.dart
import 'package:flutter/material.dart';

/// Gráfico radar comparativo de dimensiones
class RadarChartWidget extends StatelessWidget {
  final dynamic data;
  final String title;
  final double min;
  final double max;

  const RadarChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.min = 0,
    this.max = 5,
  });

  @override
  Widget build(BuildContext context) {
    
    return Center(child: Text('RadarChartWidget: $title'));
  }
}
