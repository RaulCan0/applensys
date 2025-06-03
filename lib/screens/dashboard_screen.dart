// lib/screens/dashboard_screen.dart

import 'dart:ffi';

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

// Importaciones nuevas para Supabase y nombres de tabla
import 'package:applensys/custom/table_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  // Datos crudos extraídos del cache o Supabase:
  List<Map<String, dynamic>> _dimensionesRaw = [];

  // Modelos procesados para gráficos:
  List<Dimension> _dimensiones = [];

  // Estado de Play/Pause (para el botón de la derecha)
  bool _isPlaying = false;

  // Flag para saber si aún estamos cargando
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCachedOrRemoteData();
  }

  Future<void> _loadCachedOrRemoteData() async {
    final cacheService = EvaluacionCacheService();
    await cacheService.init();

    dynamic rawTables = await cacheService.cargarTablas();

    if (rawTables != null) {
      // Si lo que viene es un Map<String, Map<String, List<Map<String, dynamic>>>>
      // desanidamos y aplanamos todas las listas interiores.
      if (rawTables is Map<String, dynamic>) {
        final List<Map<String, dynamic>> flattened = [];
        for (final dimEntry in rawTables.entries) {
          final innerMap = dimEntry.value;
          if (innerMap is Map<String, dynamic>) {
            for (final listEntry in innerMap.entries) {
              final rowsList = listEntry.value;
              if (rowsList is List<dynamic>) {
                for (final row in rowsList) {
                  if (row is Map<String, dynamic>) {
                    flattened.add(row);
                  }
                }
              }
            }
          }
        }
        _dimensionesRaw = flattened;
      }
      // Si rawTables ya era List<Map<String, dynamic>>, lo convertimos directamente:
      else if (rawTables is List<dynamic>) {
        _dimensionesRaw =
            rawTables.cast<Map<String, dynamic>>();
      }
    }

    // Si después de intentar caché no hay nada, consultamos Supabase
    if (_dimensionesRaw.isEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final data = await supabase
            .from(TableNames.detallesEvaluacion)
            .select()
            .eq('evaluacion_id', widget.evaluacionId);
        _dimensionesRaw = List<Map<String, dynamic>>.from(data as List<dynamic>);
      } catch (e) {
        debugPrint('Error cargando datos de Supabase: $e');
        _dimensionesRaw = [];
      }
    }

    // Procesar a modelos si hay registros
    if (_dimensionesRaw.isNotEmpty) {
      _procesarDimensionesDesdeRaw(_dimensionesRaw);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Convierte la lista de mapas (filas) a la estructura de modelos
  /// [Dimension], [Principio] y [Comportamiento], calculando los promedios.
  void _procesarDimensionesDesdeRaw(List<Map<String, dynamic>> raw) {
    // 1) Agrupar por 'dimension'
    final Map<String, List<Map<String, dynamic>>> porDimension = {};
    for (final fila in raw) {
      final dimNombre = (fila['dimension'] as String?) ?? 'Sin dimensión';
      porDimension.putIfAbsent(dimNombre, () => []).add(fila);
    }

    final List<Dimension> dimsModel = [];

    porDimension.forEach((dimNombre, filasDim) {
      double sumaGeneralDim = 0;
      int conteoGeneralDim = 0;

      // 2) Agrupar por 'principio' dentro de cada dimensión
      final Map<String, List<Map<String, dynamic>>> porPrincipio = {};
      for (final fila in filasDim) {
        final priNombre = (fila['principio'] as String?) ?? 'Sin principio';
        porPrincipio.putIfAbsent(priNombre, () => []).add(fila);
      }

      final List<Principio> principiosModel = [];

      porPrincipio.forEach((priNombre, filasPri) {
        double sumaPri = 0;
        int conteoPri = 0;

        // 3) Agrupar por 'comportamiento' dentro de cada principio
        final Map<String, List<Map<String, dynamic>>> porComportamiento = {};
        for (final filaP in filasPri) {
          final compNombre =
              (filaP['comportamiento'] as String?) ?? 'Sin comportamiento';
          porComportamiento.putIfAbsent(compNombre, () => []).add(filaP);
        }

        final List<Comportamiento> compsModel = [];

        porComportamiento.forEach((compNombre, filasComp) {
          double sumaEj = 0, sumaGe = 0, sumaMi = 0;

          for (final row in filasComp) {
            sumaEj += (row['ejecutivo'] as num?)?.toDouble() ?? 0.0;
            sumaGe += (row['gerente'] as num?)?.toDouble() ?? 0.0;
            sumaMi += (row['miembro'] as num?)?.toDouble() ?? 0.0;
          }

          final int nComp = filasComp.length;
          final double promEj = (nComp > 0) ? (sumaEj / nComp) : 0.0;
          final double promGe = (nComp > 0) ? (sumaGe / nComp) : 0.0;
          final double promMi = (nComp > 0) ? (sumaMi / nComp) : 0.0;

          // Construcción del modelo Comportamiento
          compsModel.add(
            Comportamiento(
              nombre: compNombre,
              promedioEjecutivo: promEj,
              promedioGerente: promGe,
              promedioMiembro: promMi,
            ),
          );

          // Para el promedio del principio: sumamos (promEj + promGe + promMi)/3
          sumaPri += ((promEj + promGe + promMi) / 3);
          conteoPri += 1;
        });

        // Promedio total del principio
        final double promedioPri =
            (conteoPri > 0) ? (sumaPri / conteoPri) : 0.0;

        // Construcción del modelo Principio
        principiosModel.add(
          Principio(
            id: priNombre,
            dimensionId: dimNombre,
            nombre: priNombre,
            promedioGeneral: promedioPri,
            comportamientos: compsModel,
          ),
        );

        // Para el promedio global de la dimensión
        sumaGeneralDim += promedioPri;
        conteoGeneralDim += 1;
      });

      // Promedio total de la dimensión
      final double promedioDim =
          (conteoGeneralDim > 0) ? (sumaGeneralDim / conteoGeneralDim) : 0.0;

      // Construcción del modelo Dimension
      dimsModel.add(
        Dimension(
          id: dimNombre,
          nombre: dimNombre,
          promedioGeneral: promedioDim,
          principios: principiosModel,
        ),
      );
    });

    _dimensiones = dimsModel;
  }

  /// Datos para el gráfico de dona (promedio general por dimensión).
  Map<String, double> _buildDonutData() {
    final Map<String, double> data = {};
    for (final dim in _dimensiones) {
      data[dim.nombre] = dim.promedioGeneral;
    }
    return data;
  }

  /// Datos para el gráfico de dispersión: un punto por cada principio
  /// (eje Y = promedioGeneral del principio, radio = cantidad de comportamientos).
  List<ScatterData> _buildScatterData() {
    final List<ScatterData> list = [];
    final principios =
        EvaluacionChartData.extractPrincipios(_dimensiones).cast<Principio>();
    for (var i = 0; i < principios.length; i++) {
      final Principio pri = principios[i];
      final double promedio = pri.promedioGeneral.clamp(0.0, 5.0);
      final double radio = pri.comportamientos.length.toDouble();
      list.add(
        ScatterData(
          x: i.toDouble(),
          y: promedio,
          radius: radio,
          color: Colors.blueAccent,
        ),
      );
    }
    return list;
  }

  /// Datos para el gráfico de barras agrupadas (comportamientos → [E, G, M]).
  Map<String, List<double>> _buildGroupedBarData() {
    final Map<String, List<double>> data = {};
    final comps =
        EvaluacionChartData.extractComportamientos(_dimensiones).cast<Comportamiento>();
    for (final comp in comps) {
      data[comp.nombre] = [
        comp.promedioEjecutivo.clamp(0.0, 5.0),
        comp.promedioGerente.clamp(0.0, 5.0),
        comp.promedioMiembro.clamp(0.0, 5.0),
      ];
    }
    return data;
  }

  /// Datos para el gráfico de barras horizontales (conteo por sistema y nivel).
  ///
  /// Recorre cada registro en _dimensionesRaw, extrae la lista de "sistemas"
  /// y cuenta cuántas veces aparece cada sistema en cada nivel (E, G, M).
  Map<String, Map<String, int>> _buildHorizontalBarsData() {
    final Map<String, Map<String, int>> data = {};

    for (final row in _dimensionesRaw) {
      // Extraer lista de sistemas desde el campo 'sistemas'
      final listaSistemas = (row['sistemas'] as List<dynamic>?)
              ?.cast<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];

      // Valores numéricos por nivel
      final double valEj = (row['ejecutivo'] as num?)?.toDouble() ?? 0.0;
      final double valGe = (row['gerente'] as num?)?.toDouble() ?? 0.0;
      final double valMi = (row['miembro'] as num?)?.toDouble() ?? 0.0;

      for (final sis in listaSistemas) {
        data.putIfAbsent(sis, () => {'E': 0, 'G': 0, 'M': 0});

        if (valEj > 0) data[sis]!['E'] = data[sis]!['E']! + 1;
        if (valGe > 0) data[sis]!['G'] = data[sis]!['G']! + 1;
        if (valMi > 0) data[sis]!['M'] = data[sis]!['M']! + 1;
      }
    }

    return data;
  }

  /// Callback al presionar “Generar Excel/Word”
  void _onGenerarDocumentos() {
    // Aquí va tu lógica real para generar Excel y Word
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando archivos Excel y Word...')),
    );
  }

  /// Callback al presionar “Play/Pause”
  void _onTogglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });
    final mensaje = _isPlaying ? 'Reanudado' : 'Pausado';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Dashboard $mensaje')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(
        width: screenSize.width * 0.8,
        child: const ChatWidgetDrawer(),
      ),
      endDrawer: SizedBox(
        width: screenSize.width * 0.8,
        child: const DrawerLensys(),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Dashboard - ${widget.empresa.nombre}',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // ► Carousel principal con 4 gráficos
          Positioned.fill(
            left: 0,
            right: screenSize.width * 0.06, // Espacio para sidebar derecho
            child: CarouselSlider.builder(
              itemCount: 4,
              itemBuilder: (context, index, realIdx) {
                switch (index) {
                  case 0:
                    return _buildChartContainer(
                      color: const Color(0xFF005F73),
                      title: 'Dimensiones',
                      child: DonutChart(
                        data: _buildDonutData(),
                        title: 'Promedio por Dimensión', dataMap: {},
                      ),
                    );
                  case 1:
                    return _buildChartContainer(
                      color: const Color(0xFF0A9396),
                      title: 'Principios',
                      child: ScatterBubbleChart(
                        data: _buildScatterData(),
                        title: 'Promedio por Principio', 
                      ),
                    );
                  case 2:
                    return _buildChartContainer(
                      color: const Color(0xFFE9D8A6),
                      title: 'Comportamientos',
                      child: GroupedBarChart(
                        data: _buildGroupedBarData(),
                        title: 'Distribución por Comportamiento y Nivel',
                        minY: 0,
                        maxY: 5,
                      ),
                    );
                  case 3:
                    return _buildChartContainer(
                      color: const Color(0xFFEE9B00),
                      title: 'Sistemas',
                      child: HorizontalBarSystemsChart(
                        data: _buildHorizontalBarsData(),
                        title: 'Conteos por Sistema y Nivel',
                        minX: 0,
                        maxX: 10,
                      ),
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
              options: CarouselOptions(
                viewportFraction: 0.9,
                enlargeCenterPage: true,
                height: double.infinity,
                enableInfiniteScroll: false,
                autoPlay: false,
              ),
            ),
          ),

          // ► Sidebar derecho (más delgado)
          Positioned(
            top: screenSize.height * 0.1,
            right: 0,
            bottom: screenSize.height * 0.1,
            child: Container(
              width: screenSize.width * 0.06,
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
                  // Icono para chat interno
                  IconButton(
                    icon: const Icon(Icons.chat, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    tooltip: 'Chat interno',
                  ),
                  const SizedBox(height: 16),

                  // Ícono para generar documentos (Excel/Word)
                  IconButton(
                    icon: const Icon(Icons.file_download, color: Colors.white),
                    onPressed: _onGenerarDocumentos,
                    tooltip: 'Generar Excel/Word',
                  ),
                  const SizedBox(height: 16),

                  // Ícono para Play/Pause
                  IconButton(
                    icon: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: _onTogglePlayPause,
                    tooltip: _isPlaying ? 'Pausar' : 'Reanudar',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Cada gráfico está dentro de un contenedor redondeado, con un título
  /// y la posibilidad de “tap” para abrir pantalla detalle (opcional).
  Widget _buildChartContainer({
    required Color color,
    required String title,
    required Widget child,
  }) {
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            // Encabezado (nombre del gráfico)
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Espacio para el gráfico en sí
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de detalle a tamaño completo (opcional) para cada gráfico.
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
      body: const Center(
        child: Text(
          'Detalle de gráfico en pantalla completa',
          style: TextStyle(fontSize: 24, color: Colors.white),
        ),
      ),
    );
  }
}
