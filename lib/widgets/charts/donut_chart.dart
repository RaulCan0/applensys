import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de pastel (PieChart) con título arriba, leyenda intermedia y porcentajes dentro.
class DonutChart extends StatelessWidget {
  /// Datos: clave → valor (promedio).
  final Map<String, double> data;
  /// Colores a usar para cada clave (debe tener tantas entradas como items en data).
  final Map<String, Color> dataMap;
  /// Si es detalle, aumenta tamaños.
  final bool isDetail;
  /// Título que aparece encima de leyenda y gráfico.


  const DonutChart({
    super.key,
    required this.data,
    required this.dataMap,
    this.isDetail = false,

  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'No hay datos para mostrar',
          style: TextStyle(
            color: Colors.white,
            fontSize: isDetail ? 18 : 14,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    final total = data.values.fold<double>(0, (sum, v) => sum + v);
    final keys = data.keys.toList();

    // Tamaños ajustables
    final double chartSize = isDetail ? 500 : 400;
    final double radius = isDetail ? 160 : 120;

    // Construcción de secciones con porcentaje interno
    final sections = <PieChartSectionData>[];
    for (var key in keys) {
      final value = data[key]!;
      final percent = total > 0 ? (value / total * 100) : 0;
      sections.add(
        PieChartSectionData(
          value: value,
          color: dataMap[key]!,
          radius: radius,
          showTitle: true,
          title: '${percent.toStringAsFixed(1)}%',
          titleStyle: TextStyle(
            fontSize: isDetail ? 18 : 16,
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 0, 0, 0),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título centrado
        Wrap(
          alignment: WrapAlignment.center,
          runSpacing: 8,
          children: keys.map((key) {
            final percent = total > 0 ? (data[key]! / total * 100).toStringAsFixed(1) : '0.0';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: isDetail ? 18 : 14,
                  height: isDetail ? 18 : 14,
                  decoration: BoxDecoration(
                    color: dataMap[key],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$key ($percent%)',
                  style: TextStyle(
                    fontSize: isDetail ? 18 : 16,
                    color: const Color.fromARGB(255, 5, 4, 4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height:20),
        // Gráfico de pastel centrado
        Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 0, // <--- Pastel sólido, no dona
                sectionsSpace: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
