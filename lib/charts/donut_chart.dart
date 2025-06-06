import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de dona (PieChart) con leyenda abajo.
/// Recibe:
///  • data: `Map<nombre_dimension, promedio>`
///  • title: String (título encima del gráfico)
///  • dataMap: opcional `Map<nombre_dimension, color>` para personalizar colores
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;
  final Map<String, Color>? dataMap;
  final bool isDetail;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
    this.dataMap,
    this.isDetail = false,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay datos para mostrar',
            style: TextStyle(color: Colors.white),
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

    return Column(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 150,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 30,
              sections: sections,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < keys.length; i++)
              _LegendItem(
                color: dataMap?[keys[i]] ??
                    fallbackPalette[i % fallbackPalette.length],
                label: keys[i],
                porcentaje: total > 0
                    ? (data[keys[i]]! / total * 100).toStringAsFixed(1)
                    : '0.0',
              ),
          ],
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String porcentaje;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.porcentaje,
  });

  @override
  Widget build(BuildContext context) {
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
          '$label ($porcentaje%)',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
