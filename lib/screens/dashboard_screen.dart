// lib/screens/dashboard_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:applensys/services/shared/excel_exporter.dart';
import 'package:flutter/material.dart';
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
      // Si viene un Map<String, Map<String, List<Map<String, dynamic>>>>
      final List<Map<String, dynamic>> flattened = [];
      if (rawTables is Map<String, dynamic>) {
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
      // Si rawTables ya era List<Map<String, dynamic>>
      else if (rawTables is List<dynamic>) {
        _dimensionesRaw = rawTables.cast<Map<String, dynamic>>();
      }
    }

    // Si no hay datos en caché, consultamos Supabase
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

    if (_dimensionesRaw.isNotEmpty) {
      _procesarDimensionesDesdeRaw(_dimensionesRaw);
    }

    setState(() {
      _isLoading = false;
    });
  }

  /// Procesa las filas crudas a modelos [Dimension], [Principio] y [Comportamiento].
  void _procesarDimensionesDesdeRaw(List<Map<String, dynamic>> raw) {
    final Map<String, List<Map<String, dynamic>>> porDimension = {};
    for (final fila in raw) {
      final dimNombre = (fila['dimension_id']?.toString()) ?? 'Sin dimensión';
      porDimension.putIfAbsent(dimNombre, () => []).add(fila);
    }

    final List<Dimension> dimsModel = [];

    porDimension.forEach((dimNombre, filasDim) {
      double sumaGeneralDim = 0;
      int conteoGeneralDim = 0;

      // Agrupar por 'principio'
      final Map<String, List<Map<String, dynamic>>> porPrincipio = {};
      for (final fila in filasDim) {
        final priNombre = (fila['principio'] as String?) ?? 'Sin principio';
        porPrincipio.putIfAbsent(priNombre, () => []).add(fila);
      }

      final List<Principio> principiosModel = [];

      porPrincipio.forEach((priNombre, filasPri) {
        double sumaPri = 0;
        int conteoPri = 0;

        // Agrupar por 'comportamiento'
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

  /// Datos para el gráfico de Dona (promedio general por dimensión).
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

  /// Construye ScatterData solo con promedios > 0 y usando orElse que
  /// devuelve un Principio vacío en lugar de null.
  List<ScatterData> _buildScatterData() {
    const List<String> allPrinciples = [
      'Respetar a Cada Individuo',
      'Liderar con Humildad',
      'Buscar la Perfección',
      'Abrazar el Pensamiento Científico',
      'Enfocarse en el Proceso',
      'Asegurar la Calidad en la Fuente',
      'Mejorar el Flujo y Jalón de Valor',
      'Pensar Sistémicamente',
      'Crear Constancia de Propósito',
      'Crear Valor para el Cliente',
    ];

    final principiosProcesados = EvaluacionChartData
        .extractPrincipios(_dimensiones)
        .cast<Principio>();

    final List<ScatterData> list = [];
    final principios =
        EvaluacionChartData.extractPrincipios(_dimensiones).cast<Principio>();

    // Cada Principio tendrá índice Y fijo de 1 a 10
    for (var i = 0; i < principios.length; i++) {
      final Principio pri = principios[i];
      final yIndex = i + 1; // 1..10

      // Calcular promedio de niveles dentro del Principio
      double sumaEj = 0, sumaGe = 0, sumaMi = 0;
      int cuentaEj = 0, cuentaGe = 0, cuentaMi = 0;

      for (final comp in pri.comportamientos) {
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

      final double promEj = (cuentaEj > 0) ? (sumaEj / cuentaEj) : 0.0;
      final double promGe = (cuentaGe > 0) ? (sumaGe / cuentaGe) : 0.0;
      final double promMi = (cuentaMi > 0) ? (sumaMi / cuentaMi) : 0.0;

      list.add(
        ScatterData(x: promEj.clamp(0.0, 5.0), y: yIndex.toDouble(), color: Colors.red),
      );
      list.add(
        ScatterData(x: promGe.clamp(0.0, 5.0), y: yIndex.toDouble(), color: Colors.green),
      );
      list.add(
        ScatterData(x: promMi.clamp(0.0, 5.0), y: yIndex.toDouble(), color: Colors.blue),
      );
    }

    return list;
  }

  /// Datos para el gráfico de Barras Agrupadas (promedios de Comportamientos).
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

  /// Datos para el gráfico de Barras Horizontales (conteo por Sistema y Nivel).
  Map<String, Map<String, double>> _buildHorizontalBarsData() { // Cambiado el tipo de retorno
    final Map<String, Map<String, double>> data = {}; // Cambiado el tipo del mapa

    for (final row in _dimensionesRaw) {
      final listaSistemas = (row['sistemas'] as List<dynamic>?)
              ?.cast<String>()
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList() ??
          <String>[];

      final valEj = (row['ejecutivo'] as num?)?.toDouble() ?? 0.0;
      final valGe = (row['gerente'] as num?)?.toDouble() ?? 0.0;
      final valMi = (row['miembro'] as num?)?.toDouble() ?? 0.0;

      for (final sis in listaSistemas) {
        data.putIfAbsent(sis, () => {'E': 0.0, 'G': 0.0, 'M': 0.0}); // Inicializar con doubles
        if (valEj > 0) data[sis]!['E'] = data[sis]!['E']! + 1.0; // Sumar como double
        if (valGe > 0) data[sis]!['G'] = data[sis]!['G']! + 1.0; // Sumar como double
        if (valMi > 0) data[sis]!['M'] = data[sis]!['M']! + 1.0; // Sumar como double
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
      // --- Preparación de datos para Excel (ya existente) ---
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
      final sistemasData = _buildHorizontalBarsData();
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

      // --- Generar Excel ---
      final excelFile = await ExcelExporter.export(
        behaviorAverages: behaviorAverages,
        systemAverages: systemAverages,
      );
      
      // --- Generar Word ---
      final t1 = await _loadJsonAsset('assets/t1.json');
      final t2 = await _loadJsonAsset('assets/t2.json');
      final t3 = await _loadJsonAsset('assets/t3.json');
      final wordPath = await ReporteUtils.exportReporteWordUnificado(
        _dimensionesRaw, 
        t1,
        t2,
        t3,
      );
      
      ScaffoldMessenger.of(context).removeCurrentSnackBar(); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10), 
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Archivos generados con éxito.'),
              Text('Excel: ${excelFile.path.split('/').last}'),
              Text('Word: ${wordPath.split('/').last}'),
            ],
          ),
          action: SnackBarAction(
            label: 'ABRIR ARCHIVOS',
            textColor: Colors.yellow,
            onPressed: () async {
              try {
                await OpenFile.open(excelFile.path);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo abrir Excel: ${e.toString()}')),
                );
              }
              try {
                if (wordPath.isNotEmpty) {
                  await OpenFile.open(wordPath);
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ruta de Word no válida.')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('No se pudo abrir Word: ${e.toString()}')),
                );
              }
            },
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar archivos: ${e.toString()}')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _loadJsonAsset(String path) async {
    final data = await DefaultAssetBundle.of(context).loadString(path);
    return List<Map<String, dynamic>>.from(jsonDecode(data));
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

      // Drawer izquierdo para chat (80% del ancho)
      drawer: SizedBox(
        width: screenSize.width * 0.8,
        child: const ChatWidgetDrawer(),
      ),

      // EndDrawer derecho normal (sin envolver en SizedBox)
      endDrawer: const DrawerLensys(),

      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
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
          // ► Lado izquierdo: ListView con los 4 gráficos (ocupa todo el espacio restante)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: ListView(
                children: [
                  // 1) Título “Dimensiones” en blanco, luego contenedor verde con su gráfico
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Dimensiones',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                   _buildChartContainer(
                    color: const Color(0xFF005F73),
                    title: 'Promedio por Dimensión',
                    child: Center( // <- Añadir Center aquí
                      child: DonutChart(
                        data: _buildDonutData(),
                        title: 'Promedio por Dimensión',
                        dataMap: {
                          'IMPULSORES CULTURALES': Colors.redAccent,
                          'MEJORA CONTINUA': Colors.yellow,
                          'ALINEAMIENTO EMPRESARIAL': Colors.lightBlueAccent,
                        },
                        isDetail: false,
                      ),
                    ),
                  ),
                  // 2) Título “Principios” en blanco, luego contenedor turquesa con su gráfico
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Principios',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildChartContainer(
                    color: const Color(0xFF0A9396),
                    title: 'Promedio por Principio',
                    child: ScatterBubbleChart(
                      data: _buildScatterData(),
                      title: 'Promedio por Principio',
                     
                      isDetail: false,
                    ),
                  ),

                  // 3) Título “Comportamientos” en blanco, luego contenedor amarillo con su gráfico
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Comportamientos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildChartContainer(
                    color: const Color(0xFFE9D8A6),
                    title: 'Distribución por Comportamiento y Nivel',
                    child: GroupedBarChart(
                      data: _buildGroupedBarData(),
                      title: 'Distribución por Comportamiento y Nivel',
                      minY: 0,
                      maxY: 5,
                      isDetail: false,
                    ),
                  ),

                  // 4) Título “Sistemas” en blanco, luego contenedor naranja con su gráfico
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'Sistemas',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildChartContainer(
                    color: const Color(0xFFEE9B00),
                    title: 'Conteos por Sistema y Nivel',
                    child: HorizontalBarSystemsChart(
                      data: _buildHorizontalBarsData(),
                      title: 'Conteos por Sistema y Nivel',
                      minX: 0,
                      maxX: 10,
                      isDetail: false,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ► Lado derecho: Sidebar estrecho con íconos (ancho 56px)
          Container(
            width: 56, // ancho normal de sidebar
            color: const Color(0xFF003056), // mismo color del AppBar
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Chat interno
                IconButton(
                  icon: const Icon(Icons.chat, color: Colors.white),
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  tooltip: 'Chat interno',
                ),
                const SizedBox(height: 16),

                // Generar Excel/Word
                IconButton(
                  icon: const Icon(Icons.file_download, color: Colors.white),
                  onPressed: _onGenerarDocumentos,
                  tooltip: 'Generar Excel/Word',
                ),
                const SizedBox(height: 16),

                // Generar y abrir Excel
                IconButton(
                  icon: const Icon(Icons.table_chart, color: Colors.green),
                  onPressed: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generando Excel...')),
                    );
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
                      final sistemasData = _buildHorizontalBarsData();
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
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Excel generado: ${excelFile.path.split('/').last}')),
                      );
                      await OpenFile.open(excelFile.path);
                    } catch (e) {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al generar o abrir Excel: ${e.toString()}')),
                      );
                    }
                  },
                  tooltip: 'Generar y Abrir Excel',
                ),
                const SizedBox(height: 16),

                // Generar y abrir Word
                IconButton(
                  icon: const Icon(Icons.description, color: Colors.blue),
                  onPressed: () async {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Generando Word...')),
                    );
                    try {
                      final t1 = await _loadJsonAsset('assets/t1.json');
                      final t2 = await _loadJsonAsset('assets/t2.json');
                      final t3 = await _loadJsonAsset('assets/t3.json');
                      final String wordPath =
                          await ReporteUtils.exportReporteWordUnificado(
                        _dimensionesRaw,
                        t1,
                        t2,
                        t3,
                      );
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      if (wordPath.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No se pudo generar Word o la ruta está vacía.')),
                        );
                        return;
                      }
                       ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Word generado: ${wordPath.split('/').last}')),
                      );
                      await OpenFile.open(wordPath);
                    } catch (e) {
                       ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al generar o abrir Word: ${e.toString()}')),
                      );
                    }
                  },
                  tooltip: 'Generar y Abrir Word',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Cada gráfico está dentro de un contenedor redondeado, con encabezado y margen.
  Widget _buildChartContainer({
    required Color color,
    required String title,
    required Widget child,
  }) {
    // Determinar chartData para validar si tiene datos
    dynamic chartData;
    switch (title) {
      case 'Promedio por Dimensión':
        chartData = _buildDonutData();
        break;
      case 'Promedio por Principio':
        chartData = _buildScatterData();
        break;
      case 'Distribución por Comportamiento y Nivel':
        chartData = _buildGroupedBarData();
        break;
      case 'Conteos por Sistema y Nivel':
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
            SnackBar(content: Text('No hay datos para mostrar en $title.')),
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
            // Encabezado interno (subtítulo) con fondo blanco
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

            // Espacio para el gráfico (alto fijo de 240px)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: 400,
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
    required this.chartData,
  });

  Widget _getChartForTitle(String title) {
    switch (title) {
      case 'Promedio por Dimensión':
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
          isDetail: true,
        );
      case 'Promedio por Principio':
        return ScatterBubbleChart(
          data: chartData is List<ScatterData> ? chartData : [],
          title: 'Promedio por Principio',
          isDetail: true,
        );
      case 'Distribución por Comportamiento y Nivel':
        return GroupedBarChart(
          data: chartData is Map<String, List<double>> ? chartData : {},
          title: 'Distribución por Comportamiento y Nivel',
          minY: 0,
          maxY: 5,
          isDetail: true,
        );
      case 'Conteos por Sistema y Nivel':
        // chartData ya debería ser Map<String, Map<String, double>>
        final Map<String, Map<String, double>> dataForChart;

        if (chartData is Map<String, Map<String, double>>) {
          dataForChart = chartData;
        } else if (chartData is Map) {
          // Fallback por si chartData no es del tipo esperado (ej. Map<String, Map<String, int>>)
          dataForChart = {};
          chartData.forEach((key, value) {
            if (value is Map) {
              final Map<String, double> innerDoubleMap = {};
              value.forEach((innerKey, innerValue) {
                if (innerValue is num) {
                  innerDoubleMap[innerKey.toString()] = innerValue.toDouble();
                }
              });
              if (innerDoubleMap.isNotEmpty) {
                dataForChart[key.toString()] = innerDoubleMap;
              }
            }
          });
        } else {
          dataForChart = {}; // Default a mapa vacío si el tipo es completamente inesperado
        }

        return HorizontalBarSystemsChart(
          data: dataForChart, // Ahora pasamos el tipo correcto
          title: 'Conteos por Sistema y Nivel',
          minX: 0,
          maxX: 10,
          isDetail: true,
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
