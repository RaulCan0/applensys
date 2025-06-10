import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class GroupedBarChart extends StatelessWidget {
  final Map<String, List<double>> data;
  final String title;
  final double minY;
  final double maxY;
  final bool isDetail;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Lista completa de comportamientos
    final comportamientosOrdenados = [
      'Soporte',
      'Reconocer',
      'Comunidad',
      'Liderazgo de Servidor',
      'Valorar',
      'Empoderar',
      'Mentalidad',
      'Estructura',
      'Reflexionar',
      'Análisis',
      'Colaborar',
      'Comprender',
      'Diseño',
      'Atribución',
      'A prueba de error',
      'Propiedad',
      'Conectar',
      'Ininterrumpido',
      'Demanda',
      'Eliminar',
      'Optimizar',
      'Impacto',
      'Alinear',
      'Aclarar',
      'Comunicar',
      'Relación',
      'Valor',
      'Medida',
    ];
    final labels = comportamientosOrdenados;

    return Column(
      children: [
        // Título
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

        // El BarChart ocupa todo el espacio restante
        Expanded(
          child: BarChart(
            BarChartData(
              minY: minY,
              maxY: maxY,
              barGroups: List.generate(labels.length, (i) {
                final valores = data[labels[i]] ?? [0.0, 0.0, 0.0];
                return BarChartGroupData(
                  x: i,
                  barsSpace: 0,
                  barRods: [
  BarChartRodData(
    toY: valores[0],
    color: Colors.orange,
    width: 12,
    borderRadius: BorderRadius.zero,
  ),
  BarChartRodData(
    toY: valores[1],
    color: Colors.green,
    width: 12,
    borderRadius: BorderRadius.zero,
  ),
  BarChartRodData(
    toY: valores[2],
    color: Colors.blue,
    width: 12,
    borderRadius: BorderRadius.zero,
  ),
],

                );
              }),
              groupsSpace: 20, // espacio entre cada grupo de 3 barras
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= labels.length) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Transform.rotate(
                          angle: -pi / 4, // rotar 45° para que quepan nombres largos
                          child: Text(
                            labels[index],
                            style: const TextStyle(fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      // Mostramos e.g. 0,1,2,3,4,5
                      if (value % 1 == 0 && value >= minY && value <= maxY) {
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
              gridData: FlGridData(
                show: true,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withAlpha(77), // 0.3 opacity
                    strokeWidth: 1,
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
