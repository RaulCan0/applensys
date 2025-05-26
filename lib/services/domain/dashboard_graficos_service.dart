import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/widgets.dart';

class BarrasPrincipiosChart extends StatelessWidget {
  final List<Map<String, dynamic>> datos;

  const BarrasPrincipiosChart({super.key, required this.datos});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
        barGroups: datos.map((principio) {
          final index = datos.indexOf(principio);
          return BarChartGroupData(x: index, barRods: [
            BarChartRodData(toY: principio['Ejecutivo'], width: 6),
            BarChartRodData(toY: principio['Gerente'], width: 6),
            BarChartRodData(toY: principio['Miembro'], width: 6),
          ]);
        }).toList(),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }
}
