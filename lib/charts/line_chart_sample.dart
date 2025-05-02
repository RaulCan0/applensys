import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/level_averages.dart';

class LineChartSample extends StatelessWidget {
  final List<LevelAverages> data;
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
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx >= 0 && idx < data.length) {
                        return Text(data[idx].nombre, style: const TextStyle(fontSize: 10));
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.ejecutivo)).toList(),
                  isCurved: true,
                  color: Colors.blue,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gerente)).toList(),
                  isCurved: true,
                  color: Colors.orange,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
                LineChartBarData(
                  spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.miembro)).toList(),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: false),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
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