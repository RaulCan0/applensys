
import 'package:applensys/charts/scatter_bubble_chart.dart' as charts;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../screens/dashboard_screen.dart';

class BehaviorsScrollChart extends StatelessWidget {
  final List<charts.ScatterBubbleData> data;
  final String title;
  final double minY;
  final double maxY;

  const BehaviorsScrollChart({
    super.key,
    required this.data,
    required this.title,
    required this.minY,
    required this.maxY,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: data.isEmpty
            ? []
            : data.asMap().entries.map((entry) {
                return SizedBox(
                  width: 50,
                  child: BarChart(
                    BarChartData(
                      minY: minY,
                      maxY: maxY,
                      barGroups: [
                        BarChartGroupData(
                          x: entry.key,
                          barRods: [
                            BarChartRodData(toY: entry.value.y, color: Colors.blue),
                          ],
                        ),
                      ],
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                    ),
                  ),
                );
              }).toList(),
      ),
    );
  }
}
