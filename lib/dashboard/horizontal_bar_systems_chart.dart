import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final String title;
  final double minY;
  final double maxY;


  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
    final colores = [Colors.blue, Colors.green, Colors.orange];
    final sistemas = data.keys.toList();

    final barGroups = List.generate(sistemas.length, (i) {
      final sistema = sistemas[i];
      return BarChartGroupData(
        x: i,
        barRods: List.generate(niveles.length, (j) {
          final nivel = niveles[j];
          final cantidad = data[sistema]?[nivel]?.toDouble() ?? 0;
          return BarChartRodData(
            toY: cantidad,
            width: 6,
            color: colores[j],
            borderRadius: BorderRadius.circular(2),
          );
        }),
      );
    });

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  alignment: BarChartAlignment.center,
                  maxY: maxY,
                  minY: minY,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < sistemas.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                sistemas[idx],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
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
