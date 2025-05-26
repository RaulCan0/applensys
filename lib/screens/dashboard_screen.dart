// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/level_averages.dart'; // Necesario para LevelAverages
import 'package:applensys/services/domain/excel_exporter.dart'; // Asegúrate que la ruta sea correcta
import 'package:applensys/services/domain/reporte_utils_final.dart';
import 'package:applensys/services/helpers/evaluation_carrousel.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/widgets/chat_scren.dart'; // Nueva importación
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

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
  final int _itemsPerPage = 10;
  int _currentPage = 0;
  List<Map<String, dynamic>> _allData = [];

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
      if (mounted) {
        setState(() {
          _allData = _flattenTableData(tablaDatos);
          _currentPage = 0;
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

  List<Map<String, dynamic>> _flattenTableData(
      Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos) {
    final flattened = <Map<String, dynamic>>[];
    tablaDatos.forEach((dim, mapEval) {
      final lista = mapEval[widget.evaluacionId];
      if (lista != null) {
        flattened.addAll(lista);
      }
    });
    return flattened;
  }

  List<Map<String, dynamic>> _getCurrentPageData() {
    if (_allData.isEmpty) return [];
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _allData.sublist(
      startIndex,
      endIndex > _allData.length ? _allData.length : endIndex,
    );
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
          // Se elimina el Builder que contenía el IconButton para abrir el endDrawer.
        ],
      ),
      endDrawer: const DrawerLensys(), 
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cargando datos...'),
                ],
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Expanded(
                      child: EvaluationCarousel(
                        evaluacionId: widget.evaluacionId,
                        empresaNombre: widget.empresa.nombre,
                        data: _getCurrentPageData(),
                        onPageChanged: (index) {
                          // Puedes implementar lógica aquí si es necesario
                          // Por ejemplo, si quieres que el carrusel controle la paginación:
                          // setState(() {
                          //   _currentPage = index; // Asumiendo que el carrusel te da el índice de la página
                          // });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: _currentPage > 0
                                ? () {
                                    if (mounted) {
                                      setState(() {
                                        _currentPage--;
                                      });
                                   }
                                 }
                                : null,
                          ),
                          Text('Página ${_currentPage + 1} de ${(_allData.length / _itemsPerPage).ceil()}'),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: (_currentPage + 1) * _itemsPerPage <
                                    _allData.length
                                ? () {
                                    if (mounted) {
                                      setState(() {
                                        _currentPage++;
                                      });
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}
