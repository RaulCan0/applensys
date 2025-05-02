import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DonutChart extends StatelessWidget {
  final List<dynamic> data;
  final String title;
  final double min;
  final double max;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sectionsSpace: 0,
        centerSpaceRadius: 40,
        sections: [
          PieChartSectionData(
            value: data.isEmpty ? 0 : data[0].value.toDouble(),
            color: Colors.blue,
            title: "Dim 1",
            radius: 50,
            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: data.isEmpty ? 0 : data[1].value.toDouble(),
            color: Colors.green,
            title: "Dim 2",
            radius: 50,
            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: data.isEmpty ? 0 : data[2].value.toDouble(),
            color: Colors.orange,
            title: "Dim 3",
            radius: 50,
            titleStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
