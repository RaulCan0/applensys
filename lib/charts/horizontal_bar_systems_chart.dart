// lib/charts/horizontal_bar_systems_chart.dart

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
    // 1) Convertimos el Map original en lista de objetos internos:
    final sistemas = data.keys.toList();
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
        // ► Título encima del gráfico
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

        // ► Gráfico propiamente dicho (ocupa todo el espacio restante)
        Expanded(
          child: SfCartesianChart(
            // — Marcamos isTransposed para que las barras salgan horizontales
            isTransposed: true,

            // — Ahora que está transpuesto:
            //    • primaryXAxis será CategoryAxis (categorías aparecen en vertical)
            //    • primaryYAxis será NumericAxis (valores en horizontal)
            primaryXAxis: CategoryAxis(
              majorGridLines: const MajorGridLines(color: Colors.grey, width: 0.5),
              axisLine: const AxisLine(color: Colors.black, width: 2),
              labelStyle: const TextStyle(fontSize: 12),
            ),
            primaryYAxis: NumericAxis(
              minimum: minX,
              maximum: maxX,
              interval: 1,
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
              // — Serie “Ejecutivo” (barra azul)
              BarSeries<_SystemSeries, String>(
                dataSource: seriesData,
                //   ■ xValueMapper debe devolver la "categoría" (String) 
                //     que luego, al estar transpuesto, se coloca en eje Y
                xValueMapper: (_SystemSeries d, _) => d.sistema,
                //   ■ yValueMapper devuelve el valor numérico (double)
                //     que se dibuja en el eje X porque está transpuesto
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

              // — Serie “Gerente” (barra roja)
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

              // — Serie “Miembro” (barra verde)
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

/// Modelo interno para unir nombre de sistema con sus conteos
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
