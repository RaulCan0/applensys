import 'package:applensys/services/domain/evaluation_chart.dart'; // Cambiado para usar la definición del domain
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ScatterBubbleChart extends StatelessWidget {
  final List<ScatterData> data;
  final String title;
  final double minValue;
  final double maxValue;

  const ScatterBubbleChart({
    super.key,
    required this.data,
    required this.title,
    this.minValue = 0,
    this.maxValue = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const Center(child: Text('Sin datos'));

    final nivelesColor = {
      'Ejecutivo': Colors.blue,
      'Gerente': Colors.green,
      'Miembro': Colors.orange,
    };

    final puntos = data.map((d) {
      final y = principios.indexOf(d.principio).toDouble();
      final x = d.valor.clamp(minValue, maxValue);
      return ScatterSpot(
        x,
        y,
        color: nivelesColor[d.nivel] ?? Colors.grey,
        radius: 7,
      );
    }).toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 400,
              child: ScatterChart(
                ScatterChartData(
                  scatterSpots: puntos,
                  minX: minValue,
                  maxX: maxValue,
                  minY: 0,
                  maxY: principios.length - 1.0,
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, _) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('${value.toInt()}', style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 160,
                        getTitlesWidget: (value, _) {
                          int i = value.toInt();
                          if (i >= 0 && i < principios.length) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(principios[i], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const List<String> principios = [
  'Respetar a cada individuo',
  'Liderar con humildad',
  'Buscar la perfección',
  'Abrazar el pensamiento científico',
  'Enfocarse en el proceso',
  'Asegurar la calidad en la fuente',
  'Mejorar el flujo y jalón de valor',
  'Pensar sistémicamente',
  'Crear constancia en el propósito',
  'Crear valor para el cliente',
];
