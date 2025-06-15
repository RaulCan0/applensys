import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de dona (PieChart) con leyenda abajo.
/// Recibe:
///  • data: `Map<nombre_dimension, promedio>`
///  • title: String (título encima del gráfico)
///  • dataMap: opcional `Map<nombre_dimension, color>` para personalizar colores
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
 
  final Map<String, Color>? dataMap;
  final bool isDetail;

  const DonutChart({
    super.key,
    required this.data,
  
    this.dataMap,
    this.isDetail = false, required String title,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        
          const SizedBox(height: 16),
          const Text(
            'No hay datos para mostrar',
            style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
          ),
        ],
      );
    }

    final total = data.values.fold<double>(0.0, (sum, val) => sum + val);

    final fallbackPalette = <Color>[
      const Color(0xFFE63946), // rojo fuerte
      const Color(0xFF2A9D8F), // verde agua
      const Color(0xFFE9C46A), // amarillo suave
    ];

    final sections = <PieChartSectionData>[];
    final keys = data.keys.toList();

    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = data[key]!;
      final color = dataMap?[key] ?? fallbackPalette[i % fallbackPalette.length];
      sections.add(
        PieChartSectionData(
          value: value,
          color: color,
          radius: 50,
          showTitle: false,
        ),
      );
    }

    // Return the PieChart widget
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: isDetail ? 200 : 150,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 30,
              sectionsSpace: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: List.generate(keys.length, (i) {
            final key = keys[i];
            final color = dataMap?[key] ?? fallbackPalette[i % fallbackPalette.length];
            final value = data[key]!;
            final porcentaje = total == 0 ? '0' : (value / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '$key ($porcentaje%)',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color.fromARGB(255, 0, 0, 0),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}