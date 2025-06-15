import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Gráfico de dona (PieChart) con título arriba, leyenda intermedia y porcentajes dentro.
class DonutChart extends StatelessWidget {
  /// Datos: clave → valor (promedio).
  final Map<String, double> data;
  /// Colores a usar para cada clave (debe tener tantas entradas como items en data).
  final Map<String, Color> dataMap;
  /// Si es detalle, aumenta tamaños.
  final bool isDetail;
  /// Título que aparece encima de leyenda y gráfico.
  final String title;

  const DonutChart({
    super.key,
    required this.data,
    required this.dataMap,
    this.isDetail = false,
    required this.title,
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
    final double chartSize = isDetail ? 250 : 200;
    final double radius = isDetail ? 80 : 60;
    final double centerSpace = isDetail ? 50 : 40;

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
            fontSize: isDetail ? 16 : 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Título centrado
        Text(
          title,
          style: TextStyle(
            fontSize: isDetail ? 22 : 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Leyenda: solo los 3 colores y etiquetas bajo título
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
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
                    fontSize: isDetail ? 14 : 12,
                    color: Colors.white,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Gráfico centrado y más grande
        Center(
          child: SizedBox(
            width: chartSize,
            height: chartSize,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: centerSpace,
                sectionsSpace: 4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
