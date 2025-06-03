// lib/charts/donut_chart.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de dona (PieChart) con leyenda abajo.
/// Recibe:
///  • data: `Map<nombre_dimension, promedio>`
///  • title: String (título encima del gráfico)
class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const DonutChart({
    super.key,
    required this.data,
    required this.title, required Map dataMap,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostramos un mensaje en lugar del gráfico
    if (data.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay datos para mostrar',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      );
    }

    // Calculamos el total para porcentajes
    final total = data.values.fold<double>(0.0, (sum, val) => sum + val);

    // Creamos una lista de colores "consistentes" para cada dimensión
    // Puedes reemplazar este listado por los colores corporativos de Lensys si los tienes definidos
    final palette = <Color>[
      const Color(0xFFE63946), // rojo fuerte
      const Color(0xFFF4A261), // naranja
      const Color(0xFF2A9D8F), // verde agua
      const Color(0xFF264653), // azul oscuro
      const Color(0xFFE9C46A), // amarillo suave
      const Color(0xFF8D99AE), // gris azulado
    ];

    // Construimos cada sección del PieChart asignando un color según el índice en data.keys
    final sections = <PieChartSectionData>[];
    final keys = data.keys.toList();
    for (var i = 0; i < keys.length; i++) {
      final key = keys[i];
      final value = data[key]!;
      final color = palette[i % palette.length];
      // Si deseas mostrar el porcentaje dentro de la dona, podrías usar:
      // final porcentaje = total > 0 ? (value / total * 100).toStringAsFixed(1) : '0.0';
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
        // Título encima del gráfico
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        // El gráfico en sí, contenido en un Container con altura fija para evitar problemas de constraints
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
        // Leyenda: cada entrada muestra un recuadro de color + nombre de dimensión + porcentaje
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            for (var i = 0; i < keys.length; i++) ...[
              _LegendItem(
                color: palette[i % palette.length],
                label: keys[i],
                porcentaje: total > 0
                    ? (data[keys[i]]! / total * 100).toStringAsFixed(1)
                    : '0.0',
              ),
            ]
          ],
        ),
      ],
    );
  }
}

/// Widget privado para cada elemento de la leyenda:
/// • Un cuadrado de color
/// • El texto: "nombre (XX.X%)"
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
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
