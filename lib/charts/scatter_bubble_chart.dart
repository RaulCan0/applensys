
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Representa cada punto (burbuja) en el ScatterBubbleChart:
class ScatterData {
  /// Posición en X
  final double x;

  /// Posición en Y
  final double y;

  /// Radio deseado (se ignorará si la librería no lo admite)
  final double radius;

  /// Color deseado (se ignorará si la librería no lo admite)
  final Color color;

  ScatterData({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
  });
}

/// Gráfico de dispersión con burbujas.
/// Los ejes X e Y están fijos de 0 a 5.
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

        // ScatterChart ocupa el espacio restante
        Expanded(
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: data.map((d) {
                // Ajustar X e Y para que no sobrepasen [0,5]
                final double x = d.x.clamp(minAxis, maxAxis);
                final double y = d.y.clamp(minAxis, maxAxis);

                // En fl_chart 1.x el constructor de ScatterSpot ya no acepta
                // los parámetros named "radius" ni "color". 
                // Para evitar errores, solo devolvemos la posición (x,y) 
                // y la librería usará tamaño y color por defecto.
                return ScatterSpot(x, y);
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
