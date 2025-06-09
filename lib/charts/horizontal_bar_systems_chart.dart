
// horizontal_bar_systems_chart.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico de barras horizontales por sistemas.
class HorizontalBarSystemsChart extends StatelessWidget {
final Map<String, Map<String, dynamic>> data;
final String title;
final double minX;
final double maxX;
final int maxY;
final int minY;

const HorizontalBarSystemsChart({
super.key,
required this.data,
required this.title,
required this.minX,
required this.maxX,
required this.maxY,
required this.minY,
});

@override
Widget build(BuildContext context) {
final List<_SystemData> chartData = [];

data.forEach((sistema, niveles) {
  final eVal = niveles['E'];
  final gVal = niveles['G'];
  final mVal = niveles['M'];
  final e = eVal is num ? eVal.toString() : double.tryParse(eVal.toDouble()) ?? 0.0;
  final g = gVal is num ? gVal.toString() : double.tryParse(gVal.toDouble()) ?? 0.0;
  final m = mVal is num ? mVal.toString() : double.tryParse(mVal.toDouble()) ?? 0.0;
 
});

if (chartData.isEmpty) {
  return const Center(
    child: Text('No hay datos disponibles', style: TextStyle(color: Colors.white, fontSize: 16)),
  );
}

return SfCartesianChart(
  title: ChartTitle(text: title, textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
  primaryXAxis: NumericAxis(
    minimum: minX,
    maximum: maxX,
    interval: 1,
    title: AxisTitle(text: 'Promedio de Uso', textStyle: const TextStyle(color: Colors.white)),
    labelStyle: const TextStyle(color: Colors.white),
  ),
  primaryYAxis: CategoryAxis(
    title: AxisTitle(text: 'Sistemas', textStyle: const TextStyle(color: Colors.white)),
    labelStyle: const TextStyle(color: Colors.white),
  ),
  legend: const Legend(isVisible: true, textStyle: TextStyle(color: Colors.white)),
  tooltipBehavior: TooltipBehavior(enable: true),
  series: <CartesianSeries<_SystemData, String>>[
    BarSeries<_SystemData, String>(
      dataSource: chartData,
      xValueMapper: (d, _) => d.sistema,
      yValueMapper: (d, _) => d.e,
      name: 'Ejecutivo',
    ),
    BarSeries<_SystemData, String>(
      dataSource: chartData,
      xValueMapper: (d, _) => d.sistema,
      yValueMapper: (d, _) => d.g,
      name: 'Gerente',
    ),
    BarSeries<_SystemData, String>(
      dataSource: chartData,
      xValueMapper: (d, _) => d.sistema,
      yValueMapper: (d, _) => d.m,
      name: 'Miembro',
    ),
  ],
);

}
}

class _SystemData {
final String sistema;
final double e;
final double g;
final double m;

_SystemData(this.sistema, this.e, this.g, this.m);
}