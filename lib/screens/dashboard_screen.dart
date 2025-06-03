// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:applensys/widgets/chat_scren.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/utils/evaluacion_chart_data.dart';
import 'package:applensys/models/dimension.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/comportamiento.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/charts/donut_chart.dart';
import 'package:applensys/charts/scatter_bubble_chart.dart';
import 'package:applensys/charts/grouped_bar_chart.dart';
import 'package:applensys/charts/horizontal_bar_systems_chart.dart';

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
  bool _isLoading = true;

  /// Estructura cruda: lista de mapas que luego convertimos a Dimension→Principio→Comportamiento
  List<Map<String, dynamic>> _dimensionesRaw = [];

  /// Modelos definitivos para los gráficos
  List<Dimension> _dimensiones = [];

  @override
  void initState() {
    super.initState();
    _loadCachedData();
  }

  Future<void> _loadCachedData() async {
    try {
      final cacheService = EvaluacionCacheService();
      await cacheService.init();

      // 1) Recuperar la estructura completa desde SharedPreferences
      final rawTables = await cacheService.cargarTablas();
      // rawTables tiene la forma:
      // {
      //   "Dimensión 1": {
      //     "eval-123": [ { fila1 }, { fila2 }, ... ]
      //   },
      //   "Dimensión 2": {
      //     "eval-123": [ { filaA }, { filaB }, ... ]
      //   },
      //   ...
      // }

      final List<Map<String, dynamic>> dimensionesList = [];

      // 2) Recorrer cada dimensión guardada
      for (final dimName in rawTables.keys) {
        final subMap = rawTables[dimName]!; 
        // subMap es Map<evaluacionId, List<Map<String, dynamic>>>

        // 2.1) Extraer únicamente las filas de la evaluación actual:
        final List<Map<String, dynamic>> filasEstaDim = 
            (subMap[widget.evaluacionId] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() 
            ?? <Map<String, dynamic>>[];

        // Si no hay filas para este evaluacionId, omitimos esta dimensión
        if (filasEstaDim.isEmpty) continue;

        // 3) Agrupar filasEstaDim por el campo "principio"
        final Map<String, List<Map<String, dynamic>>> filasPorPrincipio = {};
        for (final fila in filasEstaDim) {
          final String princ = (fila['principio'] as String?)?.trim() ?? 'SinPrincipio';
          filasPorPrincipio.putIfAbsent(princ, () => <Map<String, dynamic>>[]);
          filasPorPrincipio[princ]!.add(fila);
        }

        // 4) Construir lista de principios agregados
        final List<Map<String, dynamic>> principiosAgregados = [];

        filasPorPrincipio.forEach((principioName, filasPrincipio) {
          // 4.1) Calcular sumas de niveles
          double sumaEj = 0.0, sumaGe = 0.0, sumaMi = 0.0;
          final Set<String> sistemasUnicos = {};

          for (final row in filasPrincipio) {
            sumaEj += (row['ejecutivo'] as num?)?.toDouble() ?? 0.0;
            sumaGe += (row['gerente'] as num?)?.toDouble() ?? 0.0;
            sumaMi += (row['miembro'] as num?)?.toDouble() ?? 0.0;

            // Unir sistemas (guardados como List<String>)
            final List<String> sistemasFila =
                (row['sistemas'] as List<dynamic>?)
                    ?.cast<String>()
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
                ?? <String>[];
            sistemasUnicos.addAll(sistemasFila);
          }

          final int nComp = filasPrincipio.length;
          final double promEj = (nComp > 0) ? (sumaEj / nComp) : 0.0;
          final double promGe = (nComp > 0) ? (sumaGe / nComp) : 0.0;
          final double promMi = (nComp > 0) ? (sumaMi / nComp) : 0.0;

          // 4.2) Construir lista de comportamientos detallados
          final List<Map<String, dynamic>> comportamientosRaw = [];
          for (final row in filasPrincipio) {
            final List<String> sistemasFila =
                (row['sistemas'] as List<dynamic>?)
                    ?.cast<String>()
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
                ?? <String>[];

            comportamientosRaw.add({
              'nombre':    row['comportamiento'] ?? '',
              'ejecutivo': (row['ejecutivo'] as num?)?.toDouble() ?? 0.0,
              'gerente':   (row['gerente'] as num?)?.toDouble() ?? 0.0,
              'miembro':   (row['miembro'] as num?)?.toDouble() ?? 0.0,
              'sistemas':  sistemasFila,
              'nivel':     (row['nivel'] as String?) ?? '',
            });
          }

          // 4.3) Nodo final para este principio
          principiosAgregados.add({
            'id':              principioName,
            'nombre':          principioName,
            'promedio':        double.parse(((promEj + promGe + promMi) / 3.0).toStringAsFixed(2)),
            'sistemas':        sistemasUnicos.toList(),
            'comportamientos': comportamientosRaw,
          });
        });

        // 5) Obtener promedioDimension de la primera fila, si existe
        double promedioDimension = 0.0;
        if (filasEstaDim.first.containsKey('promedio_dimension')) {
          promedioDimension = (filasEstaDim.first['promedio_dimension'] as num).toDouble();
        }

        // 6) Agregar dimensión a la lista final
        dimensionesList.add({
          'id':         dimName,
          'nombre':     dimName,
          'promedio':   promedioDimension,
          'principios': principiosAgregados,
        });
      }

      // 7) Convertir a modelos definitivos
      final List<Dimension> dimsModel =
          EvaluacionChartData.buildDimensionesChartData(dimensionesList);

      setState(() {
        _dimensionesRaw = dimensionesList;
        _dimensiones    = dimsModel;
        _isLoading      = false;
      });
    } catch (e, st) {
      ('ERROR en _loadCachedData(): $e');
      (st);
      setState(() {
        _dimensionesRaw = [];
        _dimensiones    = [];
        _isLoading      = false;
      });
    }
  }

  /// Construye datos de dona: cada dimensión → su promedioGeneral.
  Map<String, double> _buildDonutData() {
    final Map<String, double> data = {};
    for (final dim in _dimensiones) {
      data[dim.nombre] = dim.promedioGeneral;
    }
    return data;
  }

  /// Construye datos de dispersión: un punto por cada principio (eje Y = promedio, radio = #comportamientos).
  List<ScatterData> _buildScatterData() {
    final List<ScatterData> list = [];
    final principios = EvaluacionChartData.extractPrincipios(_dimensiones);
    for (var i = 0; i < principios.length; i++) {
      final Principio pri = principios[i] as Principio;
      final double promedio = pri.promedioGeneral.clamp(0.0, 5.0);
      final double radio = pri.comportamientos.length.toDouble();
      list.add(ScatterData(
        x: i.toDouble(),
        y: promedio,
        radius: radio,
        color: Colors.blueAccent,
      ));
    }
    return list;
  }

  /// Construye datos de barras agrupadas (comportamientos → [ejecutivo, gerente, miembro]).
  Map<String, List<double>> _buildGroupedBarData() {
    final Map<String, List<double>> data = {};
    final List<Comportamiento> comps = EvaluacionChartData
        .extractComportamientos(_dimensiones)
        .cast<Comportamiento>();
    for (final comp in comps) {
      data[comp.nombre] = [
        comp.promedioEjecutivo.clamp(0.0, 5.0),
        comp.promedioGerente.clamp(0.0, 5.0),
        comp.promedioMiembro.clamp(0.0, 5.0),
      ];
    }
    return data;
  }

  /// Construye datos de barras horizontales: por cada sistema, cuento #E, #G, #M.
  Map<String, Map<String, int>> _buildHorizontalBarsData() {
    final Map<String, Map<String, int>> data = {};

    for (final dimMap in _dimensionesRaw) {
      final principiosList =
          (dimMap['principios'] as List<dynamic>).cast<Map<String, dynamic>>();
      for (final priMap in principiosList) {
        final comportamientosList = (priMap['comportamientos'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        for (final compMap in comportamientosList) {
          final List<String> sistemasList =
              (compMap['sistemas'] as List<dynamic>).cast<String>();
          final String nivel = compMap['nivel'] as String? ?? '';

          for (final sis in sistemasList) {
            data.putIfAbsent(sis, () => {'E': 0, 'G': 0, 'M': 0});
            if (nivel == 'E' || nivel == 'G' || nivel == 'M') {
              data[sis]![nivel] = data[sis]![nivel]! + 1;
            }
          }
        }
      }
    }

    return data;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(width: screenSize.width * 0.8, child: const ChatWidgetDrawer()),
      endDrawer: SizedBox(width: screenSize.width * 0.8, child: const DrawerLensys()),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.empresa.nombre,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20, // Mantener constante para evitar errores
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Center(
                  child: CarouselSlider.builder(
                    itemCount: 4,
                    options: CarouselOptions(
                      height: screenSize.height * 0.75,
                      enlargeCenterPage: true,
                      autoPlay: true,
                      aspectRatio: screenSize.width / screenSize.height,
                      enableInfiniteScroll: true,
                      autoPlayInterval: const Duration(seconds: 5),
                    ),
                    itemBuilder: (context, index, realIdx) {
                      switch (index) {
                        case 0:
                          return _buildChartContainer(
                            color: Colors.grey,
                            title: 'Dimensiones Generales',
                            child: DonutChart(
                              data: _buildDonutData(),
                              title: 'Promedio por Dimensión',
                            ),
                          );
                        case 1:
                          return _buildChartContainer(
                            color: Colors.blueGrey,
                            title: 'Principios',
                            child: ScatterBubbleChart(
                              data: _buildScatterData(),
                              title:
                                  'Principios: Promedio vs. Nº Comportamientos',
                            ),
                          );
                        case 2:
                          return _buildChartContainer(
                            color: Colors.teal,
                            title: 'Comportamientos',
                            child: GroupedBarChart(
                              data: _buildGroupedBarData(),
                              title: 'Promedios por Comportamiento',
                              minY: 0,
                              maxY: 5,
                            ),
                          );
                        case 3:
                          return _buildChartContainer(
                            color: Colors.indigo,
                            title: 'Sistemas Asociados',
                            child: HorizontalBarSystemsChart(
                              data: _buildHorizontalBarsData(),
                              title: 'Distribución por Nivel y Sistema',
                              minX: 0,
                              maxX: 5,
                            ),
                          );
                        default:
                          return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
                Positioned(
                  top: screenSize.height * 0.1,
                  right: 0,
                  bottom: screenSize.height * 0.1,
                  child: Container(
                    width: screenSize.width * 0.12,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0D3B66),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.white),
                          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                          tooltip: 'Chat interno',
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                            });
                            _loadCachedData();
                          },
                          tooltip: 'Recargar datos',
                        ),
                        SizedBox(height: screenSize.height * 0.02),
                        IconButton(
                          icon: const Icon(Icons.note_add_outlined, color: Colors.white),
                          onPressed: () {
                            // Si necesitas acción de "Agregar nota", implementa aquí.
                          },
                          tooltip: 'Agregar nota',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChartContainer({
    required Color color,
    required String title,
    required Widget child,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _SlideDetailScreen(title: title, color: color),
          ),
        );
      },
      child: Container(
        width: screenSize.width * 0.92,
        height: screenSize.height * 0.70,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _SlideDetailScreen extends StatelessWidget {
  final String title;
  final Color color;

  const _SlideDetailScreen({
    required this.title,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      appBar: AppBar(
        backgroundColor: color,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Text(
          'Detalle de "$title"',
          style: const TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
