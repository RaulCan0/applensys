import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final String title;
  final double minY;
  final double maxY;
  final List<String> sistemasOrdenados;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
    required this.sistemasOrdenados,
  });

  @override
  Widget build(BuildContext context) {
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = max(sistemasOrdenados.length * 50.0, constraints.maxHeight);
              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(scrollbars: true),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SizedBox(
                    height: chartHeight,
                    child: BarChart(
                      BarChartData(
                        minY: minY,
                        maxY: maxY,
                        barGroups: List.generate(sistemasOrdenados.length, (i) {
                          final sistema = sistemasOrdenados[i];
                          final valores = data[sistema] ?? {};
                          final e = valores['E'] ?? 0.0;
                          final g = valores['G'] ?? 0.0;
                          final m = valores['M'] ?? 0.0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(toY: e, width: 12, color: Colors.orange),
                              BarChartRodData(toY: g, width: 12, color: Colors.green),
                              BarChartRodData(toY: m, width: 12, color: Colors.blue),
                            ],
                            barsSpace: 4,
                          );
                        }),
                        groupsSpace: 18,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index >= 0 && index < sistemasOrdenados.length) {
                                  return SideTitleWidget(
                                    space: 8,
                                    meta: meta,
                                    child: Text(
                                      sistemasOrdenados[index],
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 100,
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (value) => FlLine(
                            // ignore: deprecated_member_use
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                        ),
                        barTouchData: BarTouchData(enabled: true),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
