// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class DimensionsDonutChart extends StatelessWidget {
  final double cultural;
  final double alignment;
  final double improvement;

  const DimensionsDonutChart({
    super.key,
    required this.cultural,
    required this.alignment,
    required this.improvement,
  });

  @override
  Widget build(BuildContext context) {
    final total = cultural + alignment + improvement;
    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(
            value: cultural,
            color: Colors.blue,
            title: 'Cultural\n${(cultural / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: alignment,
            color: Colors.green,
            title: 'Alignment\n${(alignment / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          PieChartSectionData(
            value: improvement,
            color: Colors.orange,
            title: 'Improvement\n${(improvement / total * 100).toStringAsFixed(1)}%',
            radius: 50,
            titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
        sectionsSpace: 2,
        centerSpaceRadius: 30,
      ),
    );
  }
}

class MonthlyLineChart extends StatelessWidget {
  final List<double> data;

  const MonthlyLineChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('M${value.toInt() + 1}'),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class PrinciplesBubbleChart extends StatelessWidget {
  final List<double> values;

  const PrinciplesBubbleChart({super.key, required this.values});

  factory PrinciplesBubbleChart.fromAverages(List<dynamic> averages) {
    final values = averages.map((e) => e.value as double).toList();
    return PrinciplesBubbleChart(values: values);
  }

  @override
  Widget build(BuildContext context) {
   final spots = values.asMap().entries
  .map((e) => ScatterSpot(e.key.toDouble(), e.value, ))
  .toList();


    return ScatterChart(
      ScatterChartData(
        scatterSpots: spots,
        minX: 0,
        maxX: values.length.toDouble(),
        minY: 0,
        maxY: values.reduce((a, b) => a > b ? a : b) + 1,
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class BehaviorsGroupedBarChart extends StatelessWidget {
  final List<double> values;

  const BehaviorsGroupedBarChart({super.key, required this.values});

  factory BehaviorsGroupedBarChart.fromAverages(List<dynamic> averages) {
    final values = averages.map((e) => e.value as double).toList();
    return BehaviorsGroupedBarChart(values: values);
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = values.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(toY: e.value, color: Colors.blue),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('B${value.toInt() + 1}'),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class SystemsVerticalBarChart extends StatelessWidget {
  final List<double> values;

  const SystemsVerticalBarChart({super.key, required this.values});

  factory SystemsVerticalBarChart.fromAverages(List<dynamic> averages) {
    final values = averages.map((e) => e.value as double).toList();
    return SystemsVerticalBarChart(values: values);
  }

  @override
  Widget build(BuildContext context) {
    final barGroups = values.asMap().entries.map((e) {
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(toY: e.value, color: Colors.green),
        ],
      );
    }).toList();

    return BarChart(
      BarChartData(
        barGroups: barGroups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('S${value.toInt() + 1}'),
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        gridData: const FlGridData(show: true),
        borderData: FlBorderData(show: true),
      ),
    );
  }
}

class RadarChartWidget extends StatelessWidget {
  final List<double> values;

  const RadarChartWidget({super.key, required this.values});

  factory RadarChartWidget.fromAverages(List<dynamic> averages) {
    final values = averages.map((e) => e.value as double).toList();
    return RadarChartWidget(values: values);
  }

  @override
  Widget build(BuildContext context) {
    final data = values.asMap().entries.map((e) => RadarEntry(value: e.value)).toList();

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            entryRadius: 3,
            dataEntries: data,
            borderColor: Colors.purple,
            fillColor: Colors.purple.withOpacity(0.3),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        radarBorderData: const BorderSide(color: Colors.grey),
        titleTextStyle: const TextStyle(fontSize: 12),
        getTitle: (index, _) => RadarChartTitle(text: 'P${index + 1}'),
      ),
    );
  }
}
