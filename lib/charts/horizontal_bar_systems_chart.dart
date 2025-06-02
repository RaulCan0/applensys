import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

/// Gráfico de barras horizontales por sistema. Recibe:
///  • data: `Map<sistema, { 'E': countE, 'G': countG, 'M': countM }>`
///    Ejemplo: { "SisA": { "E": 3, "G": 4, "M": 2 }, "SisB": { "E": 1, "G": 5, "M": 3 }, … }
///  • title: String (título encima del gráfico)
///  • minX: double (mínimo del eje X, típicamente 0)
///  • maxX: double (máximo del eje X, p.ej. 5 o 10)
class HorizontalBarSystemsChart extends StatelessWidget {
  final Map<String, Map<String, int>> data;
  final String title;
  final double minX;
  final double maxX;

  const HorizontalBarSystemsChart({
    super.key,
    required this.data,
    required this.title,
    required this.minX,
    required this.maxX,
  });

  @override
  Widget build(BuildContext context) {
    // Lista de sistemas (claves del Map)
    final sistemas = data.keys.toList();

    // Convertir cada sistema y sus conteos en un objeto _SystemSeries
    final List<_SystemSeries> seriesData = sistemas.map((sis) {
      final counts = data[sis]!;
      return _SystemSeries(
        sistema: sis,
        ejecutivo: (counts['E'] ?? 0).toDouble(),
        gerente: (counts['G'] ?? 0).toDouble(),
        miembro: (counts['M'] ?? 0).toDouble(),
      );
    }).toList();

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

        // El gráfico ocupa el espacio restante
        Expanded(
          child: SfCartesianChart(
            primaryXAxis: NumericAxis(
              minimum: minX,
              maximum: maxX,
              interval: 1,
              majorGridLines: const MajorGridLines(
                color: Colors.grey,
                width: 0.5,
              ),
              axisLine: const AxisLine(color: Colors.black, width: 2),
              labelStyle: const TextStyle(fontSize: 12),
            ),
            primaryYAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(color: Colors.grey, width: 0.5),
              axisLine: const AxisLine(color: Colors.black, width: 2),
              labelStyle: const TextStyle(fontSize: 12),
            ),
            legend: Legend(
              isVisible: true,
              position: LegendPosition.top,
              overflowMode: LegendItemOverflowMode.wrap,
            ),

            series: <CartesianSeries<_SystemSeries, String>>[
              // Serie para Ejecutivo (barras horizontales en azul)
              BarSeries<_SystemSeries, String>(
                dataSource: seriesData,
                xValueMapper: (_SystemSeries d, _) => d.sistema,
                yValueMapper: (_SystemSeries d, _) => d.ejecutivo,
                pointColorMapper: (_SystemSeries d, _) => Colors.blue,
                name: 'Ejecutivo',
                isTrackVisible: false,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                spacing: 0.2,
              ),

              // Serie para Gerente (rojo)
              BarSeries<_SystemSeries, String>(
                dataSource: seriesData,
                xValueMapper: (_SystemSeries d, _) => d.sistema,
                yValueMapper: (_SystemSeries d, _) => d.gerente,
                pointColorMapper: (_SystemSeries d, _) => Colors.red,
                name: 'Gerente',
                isTrackVisible: false,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                spacing: 0.2,
              ),

              // Serie para Miembro (verde)
              BarSeries<_SystemSeries, String>(
                dataSource: seriesData,
                xValueMapper: (_SystemSeries d, _) => d.sistema,
                yValueMapper: (_SystemSeries d, _) => d.miembro,
                pointColorMapper: (_SystemSeries d, _) => Colors.green,
                name: 'Miembro',
                isTrackVisible: false,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
                spacing: 0.2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Clase interna para mapear cada sistema y sus conteos por nivel
class _SystemSeries {
  final String sistema;
  final double ejecutivo;
  final double gerente;
  final double miembro;

  _SystemSeries({
    required this.sistema,
    required this.ejecutivo,
    required this.gerente,
    required this.miembro,
  });
}
