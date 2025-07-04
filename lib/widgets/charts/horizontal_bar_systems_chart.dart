import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final double minY;
  final double maxY;
  final List<String> sistemasOrdenados;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    
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
          height: 600, // Usa una altura fija adecuada para tu gráfico
          child: SfCartesianChart(
            primaryXAxis: const CategoryAxis(),
            primaryYAxis: NumericAxis(
              minimum: minY,
              maximum: maxY,
              interval: 1,
            ),
            series: <CartesianSeries<_SystemData, String>>[
              BarSeries<_SystemData, String>(
                name: 'Ejecutivo',
                color: Colors.orange,
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.e,
                width: 1, // <--- Haz la barra más gruesa (ajusta entre 0.7 y 1.0 según tu gusto)
              ),
              BarSeries<_SystemData, String>(
                name: 'Gerente',
                color: Colors.green,
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.g,
                width: 1, // <--- Igual aquí
              ),
              BarSeries<_SystemData, String>(
                name: 'Miembro',
                color: Colors.blue,
                dataSource: chartData,
                xValueMapper: (d, _) => d.sistema,
                yValueMapper: (d, _) => d.m,
                width: 1, // <--- Igual aquí
              ),
            ],
            legend: const Legend(isVisible: true),
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
