
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class DonutChart extends StatelessWidget {
  final Map<String, double> data;

  const DonutChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final sections = data.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        title: e.key,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.black),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
      ),
    );
  }
}
