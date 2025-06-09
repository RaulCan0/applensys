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

  // Lista de sistemas ordenada
  final sistemasOrdenados = [
    'Ambiental',
    'Comunicación',
    'Desarrollo de personal',
    'Despliegue de estrategia',
    'Gestion visual',
    'Involucramiento',
    'Medicion',
    'Mejora y alineamiento estratégico',
    'Mejora y gestion visual',
    'Planificacion',
    'Programacion y de mejora',
    'Reconocimiento',
    'Seguridad',
    'Sistemas de mejora',
    'Solucion de problemas',
    'Voz de cliente',
    'Visitas al Gemba'
  ];

  // Procesar datos para cada sistema
  for (final sistema in sistemasOrdenados) {
    final niveles = data[sistema] ?? {'E': 0.0, 'G': 0.0, 'M': 0.0};
    chartData.add(_SystemData(
      sistema,
      niveles['E']?.toDouble() ?? 0.0,
      niveles['G']?.toDouble() ?? 0.0,
      niveles['M']?.toDouble() ?? 0.0,
    ));
  }

  if (chartData.isEmpty) {
    return const Center(
      child: Text('No hay datos disponibles', style: TextStyle(color: Colors.white, fontSize: 16)),
    );
  }

  return SfCartesianChart(
    isTransposed: true,
    plotAreaBorderWidth: 0,
    title: ChartTitle(
      text: title, 
      textStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
    ),
    primaryXAxis: CategoryAxis(
      isInversed: true,
      labelStyle: const TextStyle(color: Colors.white),
      labelRotation: 0,
    ),
    primaryYAxis: NumericAxis(
      minimum: minX,
      maximum: maxX,
      interval: 1,
      labelStyle: const TextStyle(color: Colors.white),
    ),
    legend: Legend(
      isVisible: true,
      position: LegendPosition.bottom,
      textStyle: const TextStyle(color: Colors.white)
    ),
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