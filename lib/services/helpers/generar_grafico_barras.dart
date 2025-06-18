
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

Future<Uint8List> generarGrafico(String comportamiento, double ejecutivo, double gerente, double equipo) async {
  final controller = ScreenshotController();

  final chartWidget = Screenshot(
    controller: controller,
    child: Container(
      width: 400,
      height: 200,
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5.0,
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  switch (value.toInt()) {
                    case 0:
                      return Text('Ejecutivo', style: TextStyle(fontSize: 10));
                    case 1:
                      return Text('Gerente', style: TextStyle(fontSize: 10));
                    case 2:
                      return Text('Equipo', style: TextStyle(fontSize: 10));
                  }
                  return Text('');
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: [
            BarChartGroupData(x: 0, barRods: [
              BarChartRodData(toY: ejecutivo, color: Colors.blue, width: 20)
            ]),
            BarChartGroupData(x: 1, barRods: [
              BarChartRodData(toY: gerente, color: Colors.green, width: 20)
            ]),
            BarChartGroupData(x: 2, barRods: [
              BarChartRodData(toY: equipo, color: Colors.orange, width: 20)
            ]),
          ],
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
        ),
      ),
    ),
  );

  final boundary = await controller.captureFromWidget(chartWidget);
  return boundary;
}
