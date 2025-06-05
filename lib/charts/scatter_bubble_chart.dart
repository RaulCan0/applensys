import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Datos individuales de cada burbuja
class ScatterData {
  final double x; // Promedio: 0.0 - 5.0
  final double y; // Índice del principio: 1 - 10
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

  static const List<String> principles = [
    'Respetar a Cada Individuo',
    'Liderar con Humildad',
    'Buscar la Perfección',
    'Abrazar el Pensamiento Científico',
    'Enfocarse en el Proceso',
    'Asegurar la Calidad en la Fuente',
    'Mejorar el Flujo y Jalón de Valor',
    'Pensar Sistémicamente',
    'Crear Constancia de Propósito',
    'Crear Valor para el Cliente',
  ];

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(
        child: Text('No hay datos disponibles para mostrar.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );
    }

    const double minX = 0;
    const double maxX = 5;
    const double minY = 1;
    const double maxY = 10;
    final double fixedRadius = isDetail ? 14 : 8;

    return Column(
      children: [
        // Título del gráfico
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

        // Se usa Expanded para que el gráfico se ajuste al espacio disponible
        Expanded(
          child: ScatterChart(
            ScatterChartData(
              scatterSpots: data.map((d) {
                // Cada punto: x en [0..5], y en [1..10], invertido para que 1 esté arriba
                final xPos = d.x.clamp(minX, maxX);
                final yPos = (11 - d.y).clamp(minY, maxY);
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
                    showTitles: true,
                    interval: 1,
                    reservedSize: 100,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index >= 1 && index <= 10) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 4.0),
                          child: Text(
                            // Invertimos: value=10 → principles[0], value=1 → principles[9]
                            principles[10 - index],
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 0.5,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
