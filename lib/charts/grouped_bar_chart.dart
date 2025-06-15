import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GroupedBarChart extends StatelessWidget {
  final Map<String, List<double>> data;

  final double minY;
  final double maxY;
  final bool isDetail;

  const GroupedBarChart({
    super.key,
    required this.data,
    required this.minY,
    required this.maxY,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final comportamientosOrdenados = [
  'Soporte',
  'Reconocer',
  'Comunidad',
  'Liderazgo de Servidor',
  'Valorar',
  'Empoderamiento',
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
  'Medida',
  'Valor',
];
    final labels = comportamientosOrdenados;

    return Column(
      children: [
        
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = max(labels.length * 70.0, constraints.maxWidth);
             return ScrollConfiguration(
  behavior: const ScrollBehavior().copyWith(scrollbars: true),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: SizedBox(
                  width: chartWidth,
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
                              width: 14,
                              borderRadius: BorderRadius.zero,
                            ),
                            BarChartRodData(
                              toY: valores[1],
                              color: Colors.green,
                              width: 14,
                              borderRadius: BorderRadius.zero,
                            ),
                            BarChartRodData(
                              toY: valores[2],
                              color: Colors.blue,
                              width: 14,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        );
                      }),
                      groupsSpace: 20,
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                space: 6,
                                child: SizedBox(
                                  width: 70,
                                  child: Text(
                                    labels[index],
                                    style: const TextStyle(fontSize: 10),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.visible,
                                    softWrap: true,
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
                            color: Colors.grey.withAlpha(77),
                            strokeWidth: 1,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),  );
            },
          ),
        ),
      ],
    );
  }
}