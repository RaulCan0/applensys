// ignore_for_file: use_build_context_synchronously

import 'package:applensys/services/helpers/evaluation_carrousel.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
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

  Future<void> _generatePreReport() async {
    final cache = EvaluacionCacheService();
    final tablaDatos = await cache.cargarTablas();
    final sb = StringBuffer();
    sb.writeln('Dimensión,EvaluacionId,Principio,Comportamiento,Cargo,Valor,Sistemas');
    tablaDatos.forEach((dim, mapEval) {
      mapEval.forEach((evalId, lista) {
        for (var row in lista) {
          final sistemas = (row['sistemas'] as List<dynamic>?)?.join(';') ?? '';
          sb.writeln(
            '"$dim","$evalId","${row['principio']}","${row['comportamiento']}","${row['cargo_raw']}","${row['valor']}","$sistemas"'
          );
        }
      });
    });
    try {
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/pre_reporte_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File(path);
      await file.writeAsString(sb.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pre-reporte guardado en $path')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar reporte: $e')));
    }
  }

  Future<void> _exportReport() async {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pre-reporte y documento Word generados. Ver: $docPath'))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar reporte: $e'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(widget.empresa.nombre),
        backgroundColor: Colors.blue,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Expanded(
                child: EvaluationCarousel(
                  evaluacionId: widget.evaluacionId,
                  empresaNombre: widget.empresa.nombre,
                  onPageChanged: (index) {
                    // Removed unused _currentPage field
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _generatePreReport,
                      child: const Text('Generar Pre-Reporte'),
                    ),
                    ElevatedButton(
                      onPressed: _exportReport,
                      child: const Text('Exportar Reporte'),
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
