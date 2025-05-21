// ignore_for_file: use_build_context_synchronously

import 'package:applensys/services/evaluation_carrousel.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/services/evaluacion_cache_service.dart';
import 'package:applensys/services/reporte_utils_final.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
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
  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final cache = EvaluacionCacheService();
      final tablaDatos = await cache.cargarTablas();
      setState(() {
        _allData = _flattenTableData(tablaDatos);
        _currentPage = 0;
      });
    } catch (e) {
      _showError('Error al cargar datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _flattenTableData(Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos) {
    final flattened = <Map<String, dynamic>>[];
    tablaDatos.forEach((dim, mapEval) {
      // Solo agregamos las filas de la evaluación actual
      final lista = mapEval[widget.evaluacionId];
      if (lista != null) {
        flattened.addAll(lista);
      }
    });
    return flattened;
  }
  List<Map<String, dynamic>> _getCurrentPageData() {
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _allData.sublist(
      startIndex,
      endIndex > _allData.length ? _allData.length : endIndex,
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _generatePreReport() async {
    setState(() => _isLoading = true);
    try {
      final cache = EvaluacionCacheService();
      final tablaDatos = await cache.cargarTablas();
      final sb = StringBuffer();
      sb.writeln('Dimensión,EvaluacionId,Principio,Comportamiento,Cargo,Valor,Sistemas');
      
      for (var data in _allData) {
        final sistemas = (data['sistemas'] as List<dynamic>?)?.join(';') ?? '';
        sb.writeln(
          '"${data['dimension'] ?? ''}","${data['evaluacionId'] ?? ''}","${data['principio']}","${data['comportamiento']}","${data['cargo_raw']}","${data['valor']}","$sistemas"'
        );
      }
      
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/pre_reporte_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(sb.toString());
      _showSuccess('Pre-reporte guardado en $path');
    } catch (e) {
      _showError('Error al generar pre-reporte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _exportReport() async {
    setState(() => _isLoading = true);
    try {
      final t1String = await rootBundle.loadString('assets/t1.json');
      final t2String = await rootBundle.loadString('assets/t2.json');
      final t3String = await rootBundle.loadString('assets/t3.json');
      final t1 = List<Map<String, dynamic>>.from(jsonDecode(t1String));
      final t2 = List<Map<String, dynamic>>.from(jsonDecode(t2String));
      final t3 = List<Map<String, dynamic>>.from(jsonDecode(t3String));
      final cache = EvaluacionCacheService();
      final tablaDatos = await cache.cargarTablas();

      final docPath = await ReporteUtils.exportReporteWord(
        tablaDatos.values.expand((m) => m.values.expand((l) => l)).toList(),
        t1, t2, t3,
      );
      _showSuccess('Reporte exportado exitosamente: $docPath');
    } catch (e) {
      _showError('Error al exportar reporte: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(
          widget.empresa.nombre,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadInitialData,
            tooltip: 'Recargar datos',
          ),
        ],
      ),
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
                children: [                  Expanded(
                    child: EvaluationCarousel(
                      evaluacionId: widget.evaluacionId,
                      empresaNombre: widget.empresa.nombre,
                      data: _getCurrentPageData(),
                      onPageChanged: (index) {},
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),                          onPressed: _currentPage > 0 
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                        ),
                        Text(
                          'Página ${_currentPage + 1} de ${(_allData.length / _itemsPerPage).ceil()}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_forward),                          onPressed: (_currentPage + 1) * _itemsPerPage < _allData.length
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.file_download),
                          label: const Text('Pre-Reporte'),
                          onPressed: _isLoading ? null : _generatePreReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003056),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Exportar Reporte'),
                          onPressed: _isLoading ? null : _exportReport,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003056),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
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
