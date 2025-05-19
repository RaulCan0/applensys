// filepath: lib/charts/donut_chart.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico de dona con promedios por las 3 dimensiones fijas
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final double min;
  final double max;
  final String evaluacionId;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
    this.min = 0,
    this.max = 5,
    required this.evaluacionId,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = [
      _ChartData('Impulsores culturales', data['1'] ?? 0),
      _ChartData('Alineamiento empresarial', data['2'] ?? 0),
      _ChartData('Mejora continua', data['3'] ?? 0),
    ];

    return SfCircularChart(
      title: ChartTitle(text: title.isEmpty ? 'Promedio por dimensión' : title),
      legend: Legend(isVisible: true, overflowMode: LegendItemOverflowMode.wrap),
      series: <DoughnutSeries<_ChartData, String>>[
        DoughnutSeries<_ChartData, String>(
          dataSource: chartData,
          xValueMapper: (_ChartData d, _) => d.nombre,
          yValueMapper: (_ChartData d, _) => d.promedio,
          innerRadius: '60%',
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
            labelPosition: ChartDataLabelPosition.outside,
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ChartData {
  final String nombre;
  final double promedio;
  _ChartData(this.nombre, this.promedio);
}
