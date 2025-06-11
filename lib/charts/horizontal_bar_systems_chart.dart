import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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
    final chartData = sistemasOrdenados.map((s) {
      final levels = data[s] ?? {'E': 0.0, 'G': 0.0, 'M': 0.0};
      return _SystemData(
        s,
        levels['E'] ?? 0.0,
        levels['G'] ?? 0.0,
        levels['M'] ?? 0.0,
      );
    }).toList();

    if (chartData.isEmpty) {
      return const Center(child: Text('No hay datos'));
    }

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          height: chartData.length * 40.0,
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
              title: AxisTitle(text: 'Sistemas'),
            ),
            primaryYAxis: NumericAxis(
              minimum: minY,
              maximum: maxY,
              interval: 1,
              title: AxisTitle(text: 'Promedio'),
            ),
            series: <CartesianSeries<_SystemData, String>>[
              BarSeries<_SystemData, String>(
                name: 'Ejecutivo',
                color: Colors.orange, // Ejecutivo → naranja
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.e,
              ),
              BarSeries<_SystemData, String>(
                name: 'Gerente',
                color: Colors.green, // Gerente → verde
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.g,
              ),
              BarSeries<_SystemData, String>(
                name: 'Miembro',
                color: Colors.blue, // Miembro → azul
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.m,
              ),
            ],
            legend: Legend(isVisible: true),
          ),
        ),
      ),
    );
  }
}

class _SystemData {
  final String sistema;
  final double e, g, m;
  _SystemData(this.sistema, this.e, this.g, this.m);
}
