// lib/charts/scatter_bubble_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Representa cada punto “burbuja” en el ScatterBubbleChart.
/// Solo guardamos posición X, posición Y y color. El tamaño será fijo.
class ScatterData {
  /// Posición en X (normalmente el índice de un principio)
  final double x;

  /// Posición en Y (por ejemplo, el promedio que va de 0 a 5)
  final double y;

  /// Color deseado para la burbuja (por nivel)
  final Color color;

  ScatterData({
    required this.x,
    required this.y,
    required this.color,
  });
}
class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final String title;
  final bool isDetail;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    required this.title,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    // Eje X: promedio (0 a 5), Eje Y: principios (1 a 10)
    const double minX = 0;
    const double maxX = 5;
    const double minY = 1;
    const double maxY = 10;
    final double fixedRadius = isDetail ? 14 : 8;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: data.map((d) {
                final double xPos = d.x.clamp(minX, maxX);
                final double yPos = d.y.clamp(minY, maxY);
                return ScatterSpot(
                  xPos,
                  yPos,
                  dotPainter: FlDotCirclePainter(
                    radius: fixedRadius,
                    color: d.color,
                    strokeWidth: 0,
                  ),
                );
              }).toList(),
              minX: minX,
              maxX: maxX,
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(
                show: true,
                border: const Border(
                  bottom: BorderSide(color: Colors.black, width: 2),
                  left: BorderSide(color: Colors.black, width: 2),
                  right: BorderSide(color: Colors.transparent),
                  top: BorderSide(color: Colors.transparent),
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: isDetail,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value >= 1 && value <= 10 && value % 1 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: isDetail,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      if (value >= 0 && value <= 5 && value % 1 == 0) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
