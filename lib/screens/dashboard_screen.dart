import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/widgets/chat_scren.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:applensys/services/domain/reporte_utils_final.dart';
import 'package:applensys/screens/tablas_screen.dart'; // importar la fuente de datos dinámicos
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:applensys/services/helpers/excel_exporter.dart';
import 'package:applensys/services/domain/supabase_service.dart';

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
  final SupabaseService _supabase = SupabaseService();
  bool _autoPlay = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Map<String, dynamic>> slides = [
    {'color': Colors.grey, 'title': 'General'},
    {'color': Colors.blueGrey, 'title': 'Principios'},
    {'color': Colors.teal, 'title': 'Comportamientos'},
    {'color': Colors.indigo, 'title': 'Sistemas Asociados'},
  ];

  Widget _buildChart(String title) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: BarChart(BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 5,
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 3.5, color: Colors.orange)]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 4.0, color: Colors.green)]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 2.8, color: Colors.blue)]),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, m) {
            switch (v.toInt()) {
              case 0:
                return const Text('Eje');
              case 1:
                return const Text('Gte');
              case 2:
                return const Text('Miembro');
              default:
                return const Text('');
            }
          })),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 1)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
      )),
    );
  }

  Future<void> _exportReporte() async {
    try {
      // Cargar benchmarks de assets
      final t1Data = await rootBundle.loadString('assets/t1.json');
      final t2Data = await rootBundle.loadString('assets/t2.json');
      final t3Data = await rootBundle.loadString('assets/t3.json');
      final t1 = List<Map<String, dynamic>>.from(jsonDecode(t1Data));
      final t2 = List<Map<String, dynamic>>.from(jsonDecode(t2Data));
      final t3 = List<Map<String, dynamic>>.from(jsonDecode(t3Data));

      // Obtener datos dinámicos de tablaDatos para esta evaluación
      final allData = <Map<String, dynamic>>[];
      for (var dimMap in TablasDimensionScreen.tablaDatos.values) {
        final lista = dimMap[widget.evaluacionId];
        if (lista != null) {
          allData.addAll(lista);
        }
      }

      final path = await ReporteUtils.exportReporteWordUnificado(
        allData,
        t1,
        t2,
        t3,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reporte generado en: $path')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: $e')),
      );
    }
  }

  Future<void> _exportExcel() async {
    try {
      final behaviorAverages = await _supabase.getBehaviorAverages(widget.empresa.id);
      final systemAverages = await _supabase.getSystemAverages(widget.empresa.id);
      final file = await ExcelExporter.export(
        behaviorAverages: behaviorAverages,
        systemAverages: systemAverages,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel generado en: ${file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.empresa.nombre, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openEndDrawer())],
      ),
      body: Stack(
        children: [
          Center(
            child: CarouselSlider.builder(
              itemCount: slides.length,
              options: CarouselOptions(
                height: 550,
                enlargeCenterPage: true,
                autoPlay: _autoPlay,
                aspectRatio: 20/9,
                enableInfiniteScroll: true,
                autoPlayInterval: const Duration(seconds: 5),
              ),
              itemBuilder: (context, index, realIdx) {
                final color = slides[index]['color'] as Color;
                final title = slides[index]['title'] as String;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SlideDetailScreen(color: color, title: title, index: index),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.92,
                    height: 480,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white), textAlign: TextAlign.center),
                          ),
                        ),
                        Expanded(child: _buildChart(title)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
         
 Positioned(
            top: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF003056),
              ),              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(icon: const Icon(Icons.chat, color: Colors.white), onPressed: () => _scaffoldKey.currentState?.openDrawer()),
                const SizedBox(height: 20),
                IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: () {}, tooltip: 'Recargar datos'),
                IconButton(icon: const Icon(Icons.note_add_outlined, color: Colors.white), onPressed: _exportReporte, tooltip: 'Exportar Reporte'),
                IconButton(icon: FaIcon(FontAwesomeIcons.fileWord, color: Colors.white), onPressed: _exportReporte, tooltip: 'Exportar Word'),
                IconButton(icon: FaIcon(FontAwesomeIcons.fileExcel, color: Colors.white), onPressed: _exportExcel, tooltip: 'Exportar Excel'),
                IconButton(icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: () => setState(() => _autoPlay = !_autoPlay), tooltip: _autoPlay ? 'Pausar slider' : 'Reproducir slider'),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class SlideDetailScreen extends StatelessWidget {
  final Color color;
  final String title;
  final int index;

  const SlideDetailScreen({super.key, required this.color, required this.title, required this.index});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        title: Text(title),
      ),
      body: InteractiveViewer(
        panEnabled: true,
        boundaryMargin: const EdgeInsets.all(20),
        minScale: 1.0,
        maxScale: 3.0,
        child: Container(
          width: screenSize.width,
          height: screenSize.height,
          color: color,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                color: Colors.black87,
                child: Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              const Spacer(),
              Text('Detalle slide \${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 48)),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
