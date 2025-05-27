import 'package:applensys/services/domain/evaluation_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/level_averages.dart';

class LineChartSample extends StatelessWidget {
  final List<LevelAverages> data; // Cambiado de LineChartSerie a LevelAverages
  final String title;
  final String evaluacionId;
  // Eliminados minY y maxY del constructor si no se usan directamente aquí
  const LineChartSample({
    super.key,
    required this.data,
    required this.title,
    required this.evaluacionId,
    // int minY, // Eliminado
    // int maxY, // Eliminado
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }

    // Determinar minY y maxY dinámicamente si es necesario, o usar valores fijos
    // Por ejemplo, podrías calcularlos a partir de 'data' o usar constantes
    const double minYValue = 0; // Valor de ejemplo
    const double maxYValue = 5; // Valor de ejemplo

    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minYValue, // Usar el valor determinado o fijo
                  maxY: maxYValue, // Usar el valor determinado o fijo
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40), // Ajusta reservedSize según sea necesario
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < data.length) {
                            // Asumiendo que LevelAverages tiene un campo 'nombre' para las etiquetas del eje X
                            return Text(data[idx].nombre, style: const TextStyle(fontSize: 8));
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 22, // Ajusta reservedSize según sea necesario
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      // Acceder a los campos correctos de LevelAverages
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.ejecutivo)).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      // Acceder a los campos correctos de LevelAverages
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.gerente)).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                    LineChartBarData(
                      // Acceder a los campos correctos de LevelAverages
                      spots: data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.miembro)).toList(),
                      isCurved: true,
                      color: Colors.orange,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                _Legend(color: Colors.blue, text: 'Ejecutivo'),
                SizedBox(width: 12),
                _Legend(color: Colors.green, text: 'Gerente'),
                SizedBox(width: 12),
                _Legend(color: Colors.orange, text: 'Miembro'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;
  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 16, height: 4, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}
