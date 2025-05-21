import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/helpers/evaluation_chart.dart';

class GroupedBarChart extends StatelessWidget {
  final Map<String, List<double>> data;
  final String title;
  final double minY;
  final double maxY;
  final String evaluacionId;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
    required this.evaluacionId,
  });

  @override
  Widget build(BuildContext context) {
    final niveles = ['Ejecutivo', 'Gerente', 'Miembro'];
    final colores = [Colors.blue, Colors.green, Colors.orange];

    final barras = List.generate(comportamientosFijos.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: List.generate(niveles.length, (j) {
          final nivel = niveles[j];
          final valor = i < data[nivel]!.length ? data[nivel]![i] : 0.0;
          return BarChartRodData(
            toY: valor,
            color: colores[j],
            width: 6,
            borderRadius: BorderRadius.circular(2),
          );
        }),
        showingTooltipIndicators: List.generate(niveles.length, (j) => j),
      );
    });

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: BarChart(
                BarChartData(
                  barGroups: barras,
                  maxY: maxY,
                  minY: minY,
                  barTouchData: BarTouchData(enabled: true),
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 1,
                        getTitlesWidget: (value, _) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < comportamientosFijos.length) {
                            return RotatedBox(
                              quarterTurns: 1,
                              child: Text(
                                comportamientosFijos[idx],
                                style: const TextStyle(fontSize: 8),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
