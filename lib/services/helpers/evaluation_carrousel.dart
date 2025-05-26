import 'package:applensys/dashboard/donut_chart.dart';
import 'package:applensys/dashboard/grouped_bar_chart.dart';
import 'package:applensys/dashboard/horizontal_bar_systems_chart.dart';
import 'package:applensys/dashboard/line_chart_sample.dart';
import 'package:applensys/dashboard/scatter_bubble_chart.dart';
import 'package:applensys/services/domain/evaluation_chart.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class EvaluationCarousel extends StatefulWidget {
  final String evaluacionId;
  final String empresaNombre;
  final Function(int) onPageChanged;
  final int initialPage;
  final List<Map<String, dynamic>> data;
  const EvaluationCarousel({
    super.key,
    required this.evaluacionId,
    required this.empresaNombre,
    required this.onPageChanged,
    this.initialPage = 0,
    required this.data,
  });

  @override
  State<EvaluationCarousel> createState() => _EvaluationCarouselState();
}

class _EvaluationCarouselState extends State<EvaluationCarousel> {
  late final ChartsDataModel _datosGraficas;

  @override
  void initState() {
    super.initState();
    _datosGraficas = EvaluationChartDataService().procesarDatos(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final charts = [
          DonutChart(
            data: _datosGraficas.dimensionPromedios,
            title: '',
            min: 0,
            max: 5,
            evaluacionId: widget.evaluacionId,
          ),
          ...List.generate(3, (i) => LineChartSample(
            data: _datosGraficas.lineChartData,
            title: dimensionesFijas[i],
            evaluacionId: widget.evaluacionId,
            minY: 0,
            maxY: 5,
          )),
          ScatterBubbleChart(
            data: _datosGraficas.scatterData,
            title: 'Dispersión por principio',
            minValue: 0,
            maxValue: 5,
          ),
          GroupedBarChart(
            data: _datosGraficas.comportamientoPorNivel,
            title: 'Comparativa por comportamiento',
            minY: 0,
            maxY: 5,
            evaluacionId: widget.evaluacionId,
          ),
          HorizontalBarSystemsChart(
            data: _datosGraficas.sistemasPorNivel,
            title: 'Sistemas por nivel',
            minY: 0,
            maxY: 5,
          ),
        ];

        return LayoutBuilder(
          builder: (context, constraints) {
            return CarouselSlider(
              options: CarouselOptions(
                height: constraints.maxHeight,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) => widget.onPageChanged(index),
              ),
              items: charts.map((chart) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: chart,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
