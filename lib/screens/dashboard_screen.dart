// lib/screens/dashboard_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

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
import 'package:open_file/open_file.dart';
import 'package:applensys/custom/table_names.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/services/helpers/excel_exporter.dart';
import 'package:applensys/services/domain/reporte_utils_final.dart';
import 'package:applensys/models/level_averages.dart';

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
        _dimensionesRaw = rawTables.cast<Map<String, dynamic>>();
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
        _dimensionesRaw =
            List<Map<String, dynamic>>.from(data as List<dynamic>);
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
    final Map<String, List<Map<String, dynamic>>> porDimension = {};
    for (final fila in raw) {
      final dimNombre =
          (fila['dimension_id']?.toString()) ?? 'Sin dimensión';
      porDimension.putIfAbsent(dimNombre, () => []).add(fila);
    }

    final List<Dimension> dimsModel = [];

    porDimension.forEach((dimNombre, filasDim) {
      double sumaGeneralDim = 0;
      int conteoGeneralDim = 0;

      // 2) Agrupar por 'principio'
      final Map<String, List<Map<String, dynamic>>> porPrincipio = {};
      for (final fila in filasDim) {
        final priNombre = (fila['principio'] as String?) ?? 'Sin principio';
        porPrincipio.putIfAbsent(priNombre, () => []).add(fila);
      }

      final List<Principio> principiosModel = [];

      porPrincipio.forEach((priNombre, filasPri) {
        double sumaPri = 0;
        int conteoPri = 0;

        // 3) Agrupar por 'comportamiento'
        final Map<String, List<Map<String, dynamic>>> porComportamiento = {};
        for (final filaP in filasPri) {
          final compNombre =
              (filaP['comportamiento'] as String?) ?? 'Sin comportamiento';
          porComportamiento.putIfAbsent(compNombre, () => []).add(filaP);
        }

        final List<Comportamiento> compsModel = [];

        porComportamiento.forEach((compNombre, filasComp) {
          double sumaEj = 0, sumaGe = 0, sumaMi = 0;
          int countEj = 0, countGe = 0, countMi = 0;

          for (final row in filasComp) {
            final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
            final cargoRaw =
                (row['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
            if (cargoRaw.contains('ejecutivo')) {
              sumaEj += valor;
              countEj++;
            } else if (cargoRaw.contains('gerente')) {
              sumaGe += valor;
              countGe++;
            } else if (cargoRaw.contains('miembro')) {
              sumaMi += valor;
              countMi++;
            }
          }

          final double promEj = (countEj > 0) ? (sumaEj / countEj) : 0.0;
          final double promGe = (countGe > 0) ? (sumaGe / countGe) : 0.0;
          final double promMi = (countMi > 0) ? (sumaMi / countMi) : 0.0;

          compsModel.add(
            Comportamiento(
              nombre: compNombre,
              promedioEjecutivo: promEj,
              promedioGerente: promGe,
              promedioMiembro: promMi,
            ),
          );

          // Promedio general del comportamiento (solo niveles con datos)
          double sumaPromediosNivel = 0;
          int conteoNiveles = 0;
          if (countEj > 0) {
            sumaPromediosNivel += promEj;
            conteoNiveles++;
          }
          if (countGe > 0) {
            sumaPromediosNivel += promGe;
            conteoNiveles++;
          }
          if (countMi > 0) {
            sumaPromediosNivel += promMi;
            conteoNiveles++;
          }
          if (conteoNiveles > 0) {
            sumaPri += (sumaPromediosNivel / conteoNiveles);
            conteoPri++;
          }
        });

        final double promedioPri =
            (conteoPri > 0) ? (sumaPri / conteoPri) : 0.0;

        principiosModel.add(
          Principio(
            id: priNombre,
            dimensionId: dimNombre,
            nombre: priNombre,
            promedioGeneral: promedioPri,
            comportamientos: compsModel,
          ),
        );

        if (promedioPri > 0) {
          sumaGeneralDim += promedioPri;
          conteoGeneralDim++;
        }
      });

      final double promedioDim =
          (conteoGeneralDim > 0) ? (sumaGeneralDim / conteoGeneralDim) : 0.0;

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
    debugPrint('Dimensiones procesadas: ${_dimensiones.length}');
    if (_dimensiones.isNotEmpty) {
      debugPrint(
          'Primera dimensión: ${_dimensiones.first.nombre}, promedio: ${_dimensiones.first.promedioGeneral}');
    }
  }

  /// Datos para el gráfico de dona (promedio general por dimensión).
  Map<String, double> _buildDonutData() {
    const nombresDimensiones = {
      '1': 'IMPULSORES CULTURALES',
      '2': 'MEJORA CONTINUA',
      '3': 'ALINEAMIENTO EMPRESARIAL',
    };
    final Map<String, double> data = {};
    for (final dim in _dimensiones) {
      final nombre = nombresDimensiones[dim.id] ?? dim.nombre;
      data[nombre] = dim.promedioGeneral;
    }
    return data;
  }

 
List<ScatterData> _buildScatterData() {
  final List<ScatterData> list = [];
  final principios =
      EvaluacionChartData.extractPrincipios(_dimensiones).cast<Principio>();

  for (var i = 0; i < principios.length; i++) {
    final Principio pri = principios[i];

    // Si el modelo Principio NO tiene atributos 'promedioEjecutivo' directos,
    // debemos computarlos recorriendo sus comportamientos:
    double sumaEj = 0, sumaGe = 0, sumaMi = 0;
    int cuentaEj = 0, cuentaGe = 0, cuentaMi = 0;

    for (final comp in pri.comportamientos) {
      // comp.promedioEjecutivo, comp.promedioGerente, comp.promedioMiembro
      // están definidos en la clase Comportamiento:
      if (comp.promedioEjecutivo > 0) {
        sumaEj += comp.promedioEjecutivo;
        cuentaEj++;
      }
      if (comp.promedioGerente > 0) {
        sumaGe += comp.promedioGerente;
        cuentaGe++;
      }
      if (comp.promedioMiembro > 0) {
        sumaMi += comp.promedioMiembro;
        cuentaMi++;
      }
    }

    // Promedios (o 0 si no hay datos):
    final double promEj = (cuentaEj > 0) ? (sumaEj / cuentaEj) : 0.0;
    final double promGe = (cuentaGe > 0) ? (sumaGe / cuentaGe) : 0.0;
    final double promMi = (cuentaMi > 0) ? (sumaMi / cuentaMi) : 0.0;

    // Clamp para que los valores queden en 0–5:
    final double yEj = promEj.clamp(0.0, 5.0);
    final double yGe = promGe.clamp(0.0, 5.0);
    final double yMi = promMi.clamp(0.0, 5.0);

    // X fijo = índice del principio
    final double xPos = i.toDouble();

    // Agregamos los tres puntos (cada color representa un nivel distinto):
    list.add(
      ScatterData(
        x: xPos,
        y: yEj,
        color: Colors.redAccent, // Ejecutivo
      ),
    );
    list.add(
      ScatterData(
        x: xPos,
        y: yGe,
                color: Colors.blueAccent, // Miembro

      ),
    );
    list.add(
      ScatterData(
        x: xPos,
        y: yMi,
        color: Colors.greenAccent, // Gerente
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
  Map<String, Map<String, int>> _buildHorizontalBarsData() {
    final Map<String, Map<String, int>> data = {};

    for (final row in _dimensionesRaw) {
      final listaSistemas = (row['sistemas'] as List<dynamic>?)
              ?.cast<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];

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
  Future<void> _onGenerarDocumentos() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generando archivos Excel y Word...')),
    );
    try {
      // 1. Construir promedios de comportamientos para Excel
      final List<LevelAverages> behaviorAverages = [];
      int id = 1;
      for (final dim in _dimensiones) {
        for (final pri in dim.principios) {
          for (final comp in pri.comportamientos) {
            behaviorAverages.add(LevelAverages(
              id: id++,
              nombre: comp.nombre,
              ejecutivo: comp.promedioEjecutivo,
              gerente: comp.promedioGerente,
              miembro: comp.promedioMiembro,
              dimensionId: int.tryParse(dim.id),
              nivel: '',
            ));
          }
        }
      }
      // 2. Construir promedios de sistemas asociados para Excel
      final Map<String, Map<String, int>> sistemasData =
          _buildHorizontalBarsData();
      final List<LevelAverages> systemAverages = [];
      sistemasData.forEach((sistema, niveles) {
        systemAverages.add(LevelAverages(
          id: id++,
          nombre: sistema,
          ejecutivo: (niveles['E'] ?? 0).toDouble(),
          gerente: (niveles['G'] ?? 0).toDouble(),
          miembro: (niveles['M'] ?? 0).toDouble(),
          dimensionId: null,
          nivel: '',
        ));
      });
      // 3. Exportar Excel
      final excelFile = await ExcelExporter.export(
        behaviorAverages: behaviorAverages,
        systemAverages: systemAverages,
      );
      // 4. Leer benchmarks para Word
      final t1 = await _loadJsonAsset('assets/t1.json');
      final t2 = await _loadJsonAsset('assets/t2.json');
      final t3 = await _loadJsonAsset('assets/t3.json');
      // 5. Exportar Word
      final wordPath = await ReporteUtils.exportReporteWordUnificado(
        _dimensionesRaw,
        t1,
        t2,
        t3,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Archivos generados:\nExcel: ${excelFile.path}\nWord: $wordPath',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar archivos: ${e.toString()}')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadJsonAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).loadString(path);
    return List<Map<String, dynamic>>.from(jsonDecode(data));
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

  /// Callback para generar y abrir Excel inmediatamente
  Future<void> _onGenerarYAbrirExcel() async {
    try {
      final List<LevelAverages> behaviorAverages = [];
      int id = 1;
      for (final dim in _dimensiones) {
        for (final pri in dim.principios) {
          for (final comp in pri.comportamientos) {
            behaviorAverages.add(LevelAverages(
              id: id++,
              nombre: comp.nombre,
              ejecutivo: comp.promedioEjecutivo,
              gerente: comp.promedioGerente,
              miembro: comp.promedioMiembro,
              dimensionId: int.tryParse(dim.id),
              nivel: '',
            ));
          }
        }
      }
      final Map<String, Map<String, int>> sistemasData =
          _buildHorizontalBarsData();
      final List<LevelAverages> systemAverages = [];
      sistemasData.forEach((sistema, niveles) {
        systemAverages.add(LevelAverages(
          id: id++,
          nombre: sistema,
          ejecutivo: (niveles['E'] ?? 0).toDouble(),
          gerente: (niveles['G'] ?? 0).toDouble(),
          miembro: (niveles['M'] ?? 0).toDouble(),
          dimensionId: null,
          nivel: '',
        ));
      });
      final excelFile = await ExcelExporter.export(
        behaviorAverages: behaviorAverages,
        systemAverages: systemAverages,
      );
      await OpenFile.open(excelFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar/abrir Excel: ${e.toString()}')),
      );
    }
  }

  /// Callback para generar y abrir Word inmediatamente
 Future<void> _onGenerarYAbrirWord() async {
  try {
    // 1. Cargar los JSON de benchmarks
    final t1 = await _loadJsonAsset('assets/t1.json');
    final t2 = await _loadJsonAsset('assets/t2.json');
    final t3 = await _loadJsonAsset('assets/t3.json');

    // 2. Generar el documento Word (puede devolver null si ocurre algún fallo interno)
    final String wordPath = await ReporteUtils.exportReporteWordUnificado(
      _dimensionesRaw,
      t1,
      t2,
      t3,
    );

    // 3. Validar que 'wordPath' no sea null ni cadena vacía
    if (wordPath.isEmpty) {
      // Si aquí wordPath es null, mostramos un mensaje de error apropiado
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo generar el documento Word.')),
      );
      return;
    }

    // 4. Abrir el archivo Word generado
    await OpenFile.open(wordPath);
  } catch (e) {
    // En caso de cualquier otra excepción, mostramos la excepción original
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error al generar/abrir Word: ${e.toString()}')),
    );
  }
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
          onPressed: () {
            // Si quieres asegurarte de que la navegación hacia atrás no
            // encuentre dependientes vivos, puedes limpiar cualquier suscripción
            // o controlador aquí antes de hacer pop().
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Dashboard - ${widget.empresa.nombre}',
          style: const TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Row(
        children: [
          // ► Lado izquierdo: Carousel con los 4 gráficos (ocupa todo el espacio restante)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                          title: 'Promedio por Dimensión',
                          dataMap: {
                            'IMPULSORES CULTURALES': Colors.redAccent,
                            'MEJORA CONTINUA': Colors.yellow,
                            'ALINEAMIENTO EMPRESARIAL': Colors.lightBlueAccent,
                          },
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
          ),

          // ► Lado derecho: sidebar estrecho con íconos (ancho fijo)
          Container(
            width: screenSize.width * 0.08,
            color: const Color(0xFF0D3B66),
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

                // Icono para generar documentos (Excel/Word)
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  onPressed: _onGenerarDocumentos,
                  tooltip: 'Generar Excel/Word',
                ),
                const SizedBox(height: 16),

                // Icono para generar y abrir Excel
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  onPressed: _onGenerarYAbrirExcel,
                  tooltip: 'Generar y abrir Excel',
                ),
                const SizedBox(height: 16),

                // Icono para generar y abrir Word
                IconButton(
                  icon: const Icon(Icons.description, color: Colors.blue),
                  onPressed: _onGenerarYAbrirWord,
                  tooltip: 'Generar y abrir Word',
                ),
                const SizedBox(height: 16),

                // Icono para Play/Pause
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
        ],
      ),
    );
  }

  /// Cada gráfico está dentro de un contenedor redondeado, con un encabezado y espacio interior
  Widget _buildChartContainer({
    required Color color,
    required String title,
    required Widget child,
  }) {
    // Determinar chartData para evaluar si hay datos
    dynamic chartData;
    switch (title) {
      case 'Dimensiones':
        chartData = _buildDonutData();
        break;
      case 'Principios':
        chartData = _buildScatterData();
        break;
      case 'Comportamientos':
        chartData = _buildGroupedBarData();
        break;
      case 'Sistemas':
        chartData = _buildHorizontalBarsData();
        break;
      default:
        chartData = null;
    }

    return GestureDetector(
      onTap: () {
        final tieneDatos = (chartData is Map && chartData.isNotEmpty) ||
            (chartData is List && chartData.isNotEmpty);
        if (tieneDatos) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  _SlideDetailScreen(title: title, color: color, chartData: chartData),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No hay datos para mostrar en el detalle de $title.')),
          );
        }
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

            // Espacio para el gráfico en sí (usa Expanded para llenar el área disponible)
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
  final dynamic chartData;

  const _SlideDetailScreen({
    required this.title,
    required this.color,
    this.chartData,
  });

  Widget _getChartForTitle(String title) {
    switch (title) {
      case 'Dimensiones':
        return DonutChart(
          data: chartData is Map<String, double> ? chartData : {},
          title: 'Promedio por Dimensión',
          dataMap: chartData is Map<String, double>
              ? {
                  'IMPULSORES CULTURALES': Colors.redAccent,
                  'MEJORA CONTINUA': Colors.yellow,
                  'ALINEAMIENTO EMPRESARIAL': Colors.lightBlueAccent,
                }
              : {},
        );
      case 'Principios':
        return ScatterBubbleChart(
          data: chartData is List<ScatterData> ? chartData : [],
          title: 'Promedio por Principio',
        );
      case 'Comportamientos':
        return GroupedBarChart(
          data: chartData is Map<String, List<double>> ? chartData : {},
          title: 'Distribución por Comportamiento y Nivel',
          minY: 0,
          maxY: 5,
        );
      case 'Sistemas':
        final Map<String, Map<String, int>> safeData = {};
        if (chartData is Map) {
          chartData.forEach((k, v) {
            if (v is Map) {
              safeData[k.toString()] =
                  v.map((kk, vv) => MapEntry(kk.toString(), (vv as int)));
            }
          });
        }
        return HorizontalBarSystemsChart(
          data: safeData,
          title: 'Conteos por Sistema y Nivel',
          minX: 0,
          maxX: 10,
        );
      default:
        return const Center(
          child: Text(
            'No hay gráfico disponible.',
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
        );
    }
  }

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getChartForTitle(title),
      ),
    );
  }
}
