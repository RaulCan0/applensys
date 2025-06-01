
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class GroupedBarChart extends StatelessWidget {
  final Map<String, List<double>> data; // key: Principio/Dimensión, values: [E, G, M]
  final String title;
  final double minY;
  final double maxY;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.title,
    this.minY = 0,
    this.maxY = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  minY: minY,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, interval: 1),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final keys = data.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < keys.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(keys[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(data.length, (index) {
                    final label = data.keys.elementAt(index);
                    final valores = data[label]!;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(toY: valores[0], width: 8, color: Colors.blue),   // Ejecutivo
                        BarChartRodData(toY: valores[1], width: 8, color: Colors.orange), // Gerente
                        BarChartRodData(toY: valores[2], width: 8, color: Colors.green),  // Miembro
                      ],
                      showingTooltipIndicators: [0, 1, 2],
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
