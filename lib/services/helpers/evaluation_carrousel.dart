import 'package:applensys/services/helpers/evaluation_chart.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/charts/donut_chart.dart';
import 'package:applensys/charts/line_chart_sample.dart';
import 'package:applensys/charts/scatter_bubble_chart.dart';
import 'package:applensys/charts/grouped_bar_chart.dart';
import 'package:applensys/charts/horizontal_bar_systems_chart.dart';

class EvaluationCarousel extends StatefulWidget {
  final String evaluacionId;
  final String empresaNombre;
  final Function(int) onPageChanged;
  final int initialPage;

  const EvaluationCarousel({
    super.key,
    required this.evaluacionId,
    required this.empresaNombre,
    required this.onPageChanged,
    this.initialPage = 0,
  });

  @override
  State<EvaluationCarousel> createState() => _EvaluationCarouselState();
}

class _EvaluationCarouselState extends State<EvaluationCarousel> {
  late Future<ChartsDataModel> _datosGraficas;

  @override
  void initState() {
    super.initState();
    _datosGraficas = EvaluationChartDataService().cargarDatosParaGraficas(widget.evaluacionId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ChartsDataModel>(
      future: _datosGraficas,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final charts = [
          DonutChart(
            data: data.dimensionPromedios,
            title: '',
            min: 0,
            max: 5,
            evaluacionId: widget.evaluacionId,
          ),
          ...List.generate(3, (i) => LineChartSample(
            data: data.lineChartData,
            title: dimensionesFijas[i],
            evaluacionId: widget.evaluacionId,
            minY: 0,
            maxY: 5,
          )),
          ScatterBubbleChart(
            data: data.scatterData,
            title: 'Dispersión por principio',
            minValue: 0,
            maxValue: 5,
          ),
          GroupedBarChart(
            data: data.comportamientoPorNivel,
            title: 'Comparativa por comportamiento',
            minY: 0,
            maxY: 5,
            evaluacionId: widget.evaluacionId,
          ),
          HorizontalBarSystemsChart(
            data: data.sistemasPorNivel,
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
