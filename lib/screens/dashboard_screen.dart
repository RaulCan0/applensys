
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/widgets/chat_scren.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';

import '../charts/donut_chart.dart';
import '../charts/grouped_bar_chart.dart';
import '../charts/scatter_bubble_chart.dart';
import '../charts/horizontal_bar_systems_chart.dart';

class DashboardScreen extends StatefulWidget {
  final String evaluacionId;
  final Empresa empresa;

  const DashboardScreen({
    super.key,
    required this.evaluacionId,
    required this.empresa,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> slides = [
    {'title': 'General'},
    {'title': 'Principios'},
    {'title': 'Comportamientos'},
    {'title': 'Sistemas Asociados'},
  ];

  Widget _buildChart(String title) {
    switch (title) {
      case 'General':
        return DonutChart(
          title: 'Dimensiones',
          evaluacionId: widget.evaluacionId,
          data: {
            'Impulsores Culturales': 3.5,
            'Mejora Continua': 4.0,
            'Alineamiento Empresarial': 3.0,
          },
        );
      case 'Principios':
        return ScatterBubbleChart(
          title: 'Principios Evaluados',
          evaluacionId: widget.evaluacionId,
          data: [
            ScatterData(principio: '1', nivel: 'Ejecutivo', valor: 4.0),
            ScatterData(principio: '1', nivel: 'Gerente', valor: 3.5),
            ScatterData(principio: '1', nivel: 'Miembro', valor: 3.0),
            ScatterData(principio: '2', nivel: 'Ejecutivo', valor: 4.5),
            ScatterData(principio: '2', nivel: 'Gerente', valor: 3.0),
            ScatterData(principio: '2', nivel: 'Miembro', valor: 2.5),
          ],
        );
      case 'Comportamientos':
        return GroupedBarChart(
          title: 'Comportamientos',
          evaluacionId: widget.evaluacionId,
          minY: 0,
          maxY: 5,
          comportamientosFijos: ['Respeto', 'Empatía', 'Innovación', 'Escucha', 'Compromiso'],
          data: {
            'Respeto': [3.5, 4.0, 3.0],
            'Empatía': [4.0, 3.5, 3.5],
            'Innovación': [2.5, 2.0, 2.8],
            'Escucha': [4.2, 4.5, 4.0],
            'Compromiso': [3.0, 3.5, 4.0],
          },
        );
      case 'Sistemas Asociados':
        return HorizontalBarSystemsChart(
          title: 'Sistemas por Nivel',
          minY: 0,
          maxY: 5,
          data: {
            'Sistema 1': {'Ejecutivo': 3.0, 'Gerente': 2.5, 'Miembro': 3.2},
            'Sistema 2': {'Ejecutivo': 4.0, 'Gerente': 3.8, 'Miembro': 4.1},
            'Sistema 3': {'Ejecutivo': 2.5, 'Gerente': 3.0, 'Miembro': 2.9},
          },
        );
      default:
        return const Text('Gráfico no disponible');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: DrawerLensys(empresa: widget.empresa),
      endDrawer: ChatScreen(empresa: widget.empresa),
      body: SafeArea(
        child: CarouselSlider(
          options: CarouselOptions(
            height: MediaQuery.of(context).size.height,
            enlargeCenterPage: true,
            autoPlay: false,
          ),
          items: slides.map((slide) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  width: MediaQuery.of(context).size.width,
                  margin: const EdgeInsets.symmetric(horizontal: 5.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(slide['title'], style: Theme.of(context).textTheme.headline6),
                        const SizedBox(height: 16),
                        _buildChart(slide['title']),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
