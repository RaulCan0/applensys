import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class ScatterData {
  final double x; // Promedio: 0.0 - 5.0
  final double y; // Índice del principio: 1 - 10
  final Color color;
  final String seriesName;
  final String principleName;
  final double radius;

  const ScatterData({
    required this.x,
    required this.y,
    required this.color,
    required this.seriesName,
    required this.principleName,
    required this.radius, 
  });
}

/// Widget que muestra un gráfico de burbujas dispersas (scatter)
class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final bool isDetail;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    this.isDetail = false, required String title,
  });

  /// Lista de títulos de eje Y en orden natural:
  static const List<String> principleName= [
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
        child: Text(
          'No hay datos disponibles para mostrar.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }

    const double minX = 0;
    const double maxX = 5;
    const double minY = 1;
    const double maxY = 10;
    final double fixedRadius = isDetail ? 14 : 8;
    const double offset = 0.2;

    return ScatterChart(
      ScatterChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(show: true),
        borderData: FlBorderData(
          show: true,
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 2),
            left:   BorderSide(color: Colors.black, width: 2),
            right:  BorderSide(color: Colors.transparent),
            top:    BorderSide(color: Colors.transparent),
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
                if (index >= 1 && index <= principleName.length) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Text(
                      principleName[index - 1],
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
          topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        scatterSpots: data.map((d) {
          // Desplazamiento horizontal según serie
          double xPos = d.x;
          if (d.seriesName == 'Ejecutivo') {
            xPos = (d.x - offset).clamp(minX, maxX);
          } else if (d.seriesName == 'Miembro') {
            xPos = (d.x + offset).clamp(minX, maxX);
          }

          return ScatterSpot(
            xPos,
            d.y, // se usa el valor de Y directamente
            dotPainter: FlDotCirclePainter(
              radius: d.radius, // usa el radius definido
              color: d.color,
              strokeWidth: 0,
            ),
          );
        }).toList(),
      ),
    );
  }
}
