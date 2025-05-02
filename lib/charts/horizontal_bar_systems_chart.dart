// ARCHIVO: horizontal_bar_systems_chart.dart
import 'package:applensys/models/level_averages.dart' as models;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../charts/scatter_bubble_chart.dart'; // Asegura importar el modelo correcto

class HorizontalBarSystemsChart extends StatelessWidget {
  final List<models.LevelAverages> data;
  final String title;
  final double min;
  final double max;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    this.min = 0,
    this.max = 5, required int minY, required int maxY,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: BarChart(
              BarChartData(
                minY: min,
                maxY: max,
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx >= 0 && idx < data.length) {
                          return Text(
                            data[idx].nombre,
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barGroups: data.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final e = entry.value;
                  return BarChartGroupData(
                    x: idx,
                    barRods: [
                      BarChartRodData(toY: e.ejecutivo, width: 8, color: Colors.blue),
                      BarChartRodData(toY: e.gerente, width: 8, color: Colors.orange),
                      BarChartRodData(toY: e.miembro, width: 8, color: Colors.green),
                    ],
                    barsSpace: 4,
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            _Legend(color: Colors.blue, text: 'Ejecutivo'),
            SizedBox(width: 12),
            _Legend(color: Colors.orange, text: 'Gerente'),
            SizedBox(width: 12),
            _Legend(color: Colors.green, text: 'Miembro'),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 4, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
