// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/level_averages.dart'; 
import 'package:applensys/services/domain/excel_exporter.dart'; 
import 'package:applensys/services/domain/reporte_utils_final.dart';
import 'package:applensys/services/helpers/evaluation_carrousel.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/widgets/chat_scren.dart'; 
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:path_provider/path_provider.dart'; // Comentado si no se usa directamente aquí
import 'package:applensys/services/domain/evaluation_chart.dart'; // Asegurar que ChartsDataModel y EvaluationChartDataService estén exportados y sean accesibles
import 'package:applensys/services/domain/evaluation_chart.dart' show dimensionesFijas; 
import 'package:applensys/dashboard/donut_chart.dart';
import 'package:applensys/dashboard/grouped_bar_chart.dart';
import 'package:applensys/dashboard/horizontal_bar_systems_chart.dart';
import 'package:applensys/dashboard/line_chart_sample.dart';
import 'package:applensys/dashboard/scatter_bubble_chart.dart'; // Descomentada la importación de ScatterBubbleChart

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
  bool _isLoading = false;
  List<Map<String, dynamic>> _allData = [];
  ChartsDataModel? _chartsData;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final cache = EvaluacionCacheService();
      final tablaDatos = await cache.cargarTablas();
      // Aplana datos solo para esta evaluación
      final datos = <Map<String, dynamic>>[];
      tablaDatos.forEach((_, mapa) {
        final lista = mapa[widget.evaluacionId];
        if (lista != null) datos.addAll(lista);
      });
      // Procesa todos los gráficos de una vez
      final modelo = EvaluationChartDataService().procesarDatos(datos);
      if (mounted) {
        setState(() {
          _allData = datos;
          _chartsData = modelo;
        });
      }
    } catch (e) {
      _showError('Error al cargar datos: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _exportCombinedReport() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // 1. Exportar a Excel
      // Necesitarás transformar _allData o cargar/calcular los LevelAverages correspondientes.
      final List<LevelAverages> behaviorAveragesForExcel = []; // Placeholder
      final List<LevelAverages> systemAveragesForExcel = []; // Placeholder

      final excelFile = await ExcelExporter.export(
        behaviorAverages: behaviorAveragesForExcel,
        systemAverages: systemAveragesForExcel,
      );
      _showSuccess('Reporte Excel guardado en: ${excelFile.path}');

      // 2. Exportar a Word
      final t1String = await rootBundle.loadString('assets/t1.json');
      final t2String = await rootBundle.loadString('assets/t2.json');
      final t3String = await rootBundle.loadString('assets/t3.json');
      final t1 = List<Map<String, dynamic>>.from(jsonDecode(t1String) as List);
      final t2 = List<Map<String, dynamic>>.from(jsonDecode(t2String) as List);
      final t3 = List<Map<String, dynamic>>.from(jsonDecode(t3String) as List);

      // _allData ya está filtrada por evaluacionId en _loadInitialData y _flattenTableData
      // Corregido el nombre de la función a exportReporteWordUnificado
      final docPath = await ReporteUtils.exportReporteWordUnificado(
        _allData, // Usar _allData que ya está filtrada y aplanada
        t1,
        t2,
        t3,
      );
      _showSuccess('Reporte Word exportado exitosamente: $docPath');
    } catch (e) {
      _showError('Error al exportar reporte combinado: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.empresa.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true, // Centrar el título
        iconTheme: const IconThemeData(color: Colors.white), // Asegura que la flecha de retroceso (si aplica) sea blanca
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData,
            tooltip: 'Recargar datos',
          ),
          IconButton( // Botón de exportar movido al AppBar
            icon: const Icon(Icons.note_add_outlined), // Nuevo icono para exportar
            onPressed: _isLoading ? null : _exportCombinedReport,
            tooltip: 'Exportar Reporte',
          ),
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: const DrawerLensys(), 
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, // Centrar el contenido de la columna
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos...'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                if (_chartsData == null) {
                  return const Center(child: Text('No hay datos para mostrar.'));
                }
                // Usar la importación específica de dimensionesFijas si es necesario aquí
                // final List<String> lineChartTitles = dimensionesFijas; 

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      SizedBox(
                        height: constraints.maxHeight * 0.4, // Ajustar altura según necesidad
                        child: EvaluationCarousel(
                          evaluacionId: widget.evaluacionId,
                          empresaNombre: widget.empresa.nombre,
                          data: _allData, // Pasar _allData al carrusel
                          onPageChanged: (index) {
                            // Lógica si es necesario al cambiar de página en el carrusel
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Ejemplo de cómo podrías querer mostrar los gráficos individualmente
                      // si no están todos en el carrusel o si quieres duplicarlos.
                      if (_chartsData!.lineChartData.isNotEmpty)
                        SizedBox(
                          height: 300, // Altura fija para el gráfico de línea
                          child: LineChartSample(
                            data: _chartsData!.lineChartData,
                            title: 'Promedios por Nivel y Dimensión', // Título general
                            evaluacionId: widget.evaluacionId,
                            // minY y maxY ya no se pasan como parámetros
                          ),
                        ),
                      if (_chartsData!.dimensionPromedios.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: DonutChart(
                            data: _chartsData!.dimensionPromedios,
                            title: 'Promedio General por Dimensión',
                            evaluacionId: widget.evaluacionId,
                            min: 0,
                            max: 5, 
                          ),
                        ),
                      if (_chartsData!.comportamientoPorNivel.isNotEmpty)
                        SizedBox(
                          height: 350,
                          child: GroupedBarChart(
                            data: _chartsData!.comportamientoPorNivel,
                            title: 'Comparativa de Comportamientos por Nivel',
                            evaluacionId: widget.evaluacionId,
                             minY: 0, // Estos pueden ser necesarios dependiendo de la implementación de GroupedBarChart
                             maxY: 5,
                          ),
                        ),
                      if (_chartsData!.sistemasPorNivel.isNotEmpty)
                        SizedBox(
                          height: 300,
                          child: HorizontalBarSystemsChart(
                            data: _chartsData!.sistemasPorNivel,
                            title: 'Conteo de Sistemas por Nivel',
                             minY: 0, // Estos pueden ser necesarios
                             maxY: 5,
                          ),
                        ),
                      if (_chartsData!.scatterData.isNotEmpty)
                        SizedBox(
                          height: 350,
                          child: ScatterBubbleChart(
                            data: _chartsData!.scatterData,
                            title: 'Dispersión de Principios/Comportamientos',
                            minValue: 0,
                            maxValue: 5,
                          ),
                        ),
                      // Añadir más gráficos según sea necesario
                    ],
                  ),
                );
              },
            ),
    );
  }
}
