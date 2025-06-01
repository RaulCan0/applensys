
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class DonutChart extends StatelessWidget {
  final Map<String, double> data;
  final String title;

  const DonutChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final chartData = data.entries
        .map((e) => _ChartData(e.key, e.value))
        .toList();

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: SfCircularChart(
                legend: Legend(isVisible: true),
                series: <CircularSeries>[
                  DoughnutSeries<_ChartData, String>(
                    dataSource: chartData,
                    xValueMapper: (_ChartData d, _) => d.label,
                    yValueMapper: (_ChartData d, _) => d.value,
                    dataLabelSettings: const DataLabelSettings(isVisible: true),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String label;
  final double value;
  _ChartData(this.label, this.value);
}
