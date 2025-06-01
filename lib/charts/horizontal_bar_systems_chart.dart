
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, int>> data; // {sistema: {nivel: cantidad}}
  final String title;
  final double minY;
  final double maxY;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    this.minY = 0,
    this.maxY = 10,
  });

  @override
  Widget build(BuildContext context) {
    final sistemaLabels = data.keys.toList();

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
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < sistemaLabels.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(sistemaLabels[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(show: true),
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: minY,
                  barGroups: List.generate(data.length, (index) {
                    final sistema = sistemaLabels[index];
                    final niveles = data[sistema]!;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(toY: (niveles['E'] ?? 0).toDouble(), width: 6, color: Colors.blue),
                        BarChartRodData(toY: (niveles['G'] ?? 0).toDouble(), width: 6, color: Colors.orange),
                        BarChartRodData(toY: (niveles['M'] ?? 0).toDouble(), width: 6, color: Colors.green),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
