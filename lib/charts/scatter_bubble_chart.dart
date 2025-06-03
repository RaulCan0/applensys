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

/// Gráfico de dispersión con “burbujas” de tamaño constante.
/// Ejes fijos de 0 a 5 (tanto en X como en Y).
class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final String title;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Rango fijo de ejes de 0 a 5
    const double minAxis = 0;
    const double maxAxis = 5;

    // Radio fijo para todas las burbujas
    const double fixedRadius = 8;

    return Column(
      children: [
        // Título encima del gráfico
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

        // ScatterChart ocupa el resto del espacio disponible
        Expanded(
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: data.map((d) {
                // Clamp para que X e Y queden dentro de [0, 5]
                final double xPos = d.x.clamp(minAxis, maxAxis);
                final double yPos = d.y.clamp(minAxis, maxAxis);

                // Creamos un ScatterSpot con tamaño fijo y color d.color:
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
              minX: minAxis,
              maxX: maxAxis,
              minY: minAxis,
              maxY: maxAxis,
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
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // Muestra 0, 1, 2, 3, 4, 5 en el eje Y
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
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      // Muestra 0, 1, 2, 3, 4, 5 en el eje X
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
