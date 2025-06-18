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

    // Configuración del Tooltip
    final TooltipBehavior tooltipBehavior = TooltipBehavior(
      enable: true,
       // Se activa al tocar
      // El builder permite personalizar el contenido del tooltip
      builder: (dynamic data, dynamic point, dynamic series, int pointIndex, int seriesIndex) {
        final _SystemData systemData = data as _SystemData;
        final String seriesName = series.name ?? 'Nivel'; // Nombre de la serie (Ejecutivo, Gerente, Miembro)
        double value = 0.0;

        // Determinar el valor basado en la serie que se tocó
        if (seriesName == 'Ejecutivo') {
          value = systemData.e;
        } else if (seriesName == 'Gerente') {
          value = systemData.g;
        } else if (seriesName == 'Miembro') {
          value = systemData.m;
        }
        
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'Sistema: ${systemData.sistema}\n$seriesName: ${value.toStringAsFixed(2)}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        );
      }
    );

    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: true),
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SizedBox(
          height: chartData.length * 40.0, 
          child: SfCartesianChart(
            primaryXAxis: CategoryAxis(
            ),
            primaryYAxis: NumericAxis(
              minimum: minY,
              maximum: maxY,
              interval: 1, // Ajusta el intervalo si es necesario para promedios (ej. 0.5 o 1)
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
                yValueMapper: (d, _) => d.g, // Corregido: debería ser d.g para Gerente
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
            tooltipBehavior: tooltipBehavior, // <-- Añadir esta línea
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
