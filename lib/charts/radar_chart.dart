import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/level_averages.dart';

class RadarChartWidget extends StatelessWidget {
  final List<LevelAverages> data;
  final String title;
  final double min;
  final double max;

  const RadarChartWidget({
    super.key,
    required this.data,
    required this.title,
    this.min = 0,
    this.max = 5,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('Sin datos'));
    }
    return Column(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Expanded(
          child: RadarChart(
            RadarChartData(
              dataSets: [
                RadarDataSet(
                  dataEntries: data.map((e) => RadarEntry(value: e.general)).toList(),
                  borderColor: Colors.blue,
                  // ignore: deprecated_member_use
                  fillColor: Colors.blue.withOpacity(0.3),
                  entryRadius: 3,
                  borderWidth: 2,
                ),
              ],
              radarBackgroundColor: Colors.transparent,
              tickCount: 5,
              titleTextStyle: const TextStyle(fontSize: 10),
              radarBorderData: const BorderSide(color: Colors.blue),
              tickBorderData: const BorderSide(color: Colors.grey),
              gridBorderData: const BorderSide(color: Colors.grey),
              radarShape: RadarShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}