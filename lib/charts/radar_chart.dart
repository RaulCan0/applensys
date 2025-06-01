import 'package:flutter/material.dart';
import 'dart:math';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> data;
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
              height: 300,
              child: CustomPaint(
                painter: RadarChartPainter(data: data, max: max),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RadarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double max;

  RadarChartPainter({required this.data, required this.max});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2.5;
    final angle = (2 * pi) / data.length;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke;

    // Draw web lines
    for (int i = 1; i <= 5; i++) {
      final r = radius * (i / 5);
      final path = Path();
      for (int j = 0; j < data.length; j++) {
        final x = center.dx + r * cos(j * angle - pi / 2);
        final y = center.dy + r * sin(j * angle - pi / 2);
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }

    // Draw axes and labels
    final axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: Colors.black, fontSize: 12);

    int index = 0;
    for (String label in data.keys) {
      final x = center.dx + radius * cos(index * angle - pi / 2);
      final y = center.dy + radius * sin(index * angle - pi / 2);
      canvas.drawLine(center, Offset(x, y), axisPaint);

      final textSpan = TextSpan(text: label, style: labelStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(minWidth: 0, maxWidth: 100);
      canvas.save();
      canvas.translate(x, y);
      textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
      canvas.restore();

      index++;
    }

    // Draw data polygon
    final dataPath = Path();
    final dataPaint = Paint()
      ..color = Colors.blue.withAlpha((0.5 * 255).toInt())
      ..style = PaintingStyle.fill;

    index = 0;
    for (double value in data.values) {
      final r = (value / max) * radius;
      final x = center.dx + r * cos(index * angle - pi / 2);
      final y = center.dy + r * sin(index * angle - pi / 2);
      if (index == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
      index++;
    }
    dataPath.close();
    canvas.drawPath(dataPath, dataPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/*import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class RadarChartWidget extends StatelessWidget {
  final Map<String, double> data;
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
    final chartData = data.entries
        .map((e) => _RadarData(e.key, e.value))
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
              height: 300,
              child: SfRadarChart(
                primaryXAxis: CategoryAxis(),
                primaryYAxis: NumericAxis(minimum: min, maximum: max, interval: 1),
                series: <RadarSeries<_RadarData, String>>[
                  RadarSeries<_RadarData, String>(
                    dataSource: chartData,
                    xValueMapper: (_RadarData d, _) => d.label,
                    yValueMapper: (_RadarData d, _) => d.value,
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

class _RadarData {
  final String label;
  final double value;
  _RadarData(this.label, this.value);
}
*/