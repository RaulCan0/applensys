import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico de barras horizontales por sistema. Recibe:
///  • data: `Map<sistema, { 'E': promedioE, 'G': promedioG, 'M': promedioM }>`
///  • title: String (título encima del gráfico)
class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, double>> data;
  final String title;
  final double minX;
  final double maxX;
  final bool isDetail;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    required this.minX,
    required this.maxX,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    final List<_SystemData> chartData = [];

    data.forEach((sistema, niveles) {
      chartData.add(_SystemData(sistema, niveles['E'] ?? 0, niveles['G'] ?? 0, niveles['M'] ?? 0));
    });

    if (data.isEmpty) {
      return Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return SfCartesianChart(
      title: ChartTitle(
        text: title,
        textStyle: TextStyle(
          fontSize: isDetail ? 20 : 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      primaryXAxis: NumericAxis(
        minimum: minX,
        maximum: maxX,
        interval: 1,
        title: AxisTitle(text: 'Promedio de Uso', textStyle: TextStyle(color: Colors.white)),
        labelStyle: const TextStyle(color: Colors.white),
        majorGridLines: const MajorGridLines(width: 0.2),
      ),
      primaryYAxis: CategoryAxis(
        title: AxisTitle(text: 'Sistemas', textStyle: TextStyle(color: Colors.white)),
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
          color: Colors.red,
        ),
        BarSeries<_SystemData, String>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.sistema,
          yValueMapper: (d, _) => d.g,
          name: 'Gerente',
          color: Colors.green,
        ),
        BarSeries<_SystemData, String>(
          dataSource: chartData,
          xValueMapper: (d, _) => d.sistema,
          yValueMapper: (d, _) => d.m,
          name: 'Miembro',
          color: Colors.blue,
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