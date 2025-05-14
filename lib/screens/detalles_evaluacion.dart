import 'package:applensys/models/empresa.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import '../widgets/drawer_lensys.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:applensys/providers/app_provider.dart';
import 'package:provider/provider.dart';
import 'package:applensys/services/prereporte_generator.dart';

class DetallesEvaluacionScreen extends StatefulWidget {
  /// Mapa de dimensiones a sus promedios por nivel (Ejecutivo, Gerente, Miembro, General)
  final Map<String, Map<String, double>> dimensionesPromedios;
  final Empresa empresa;
  final String evaluacionId;

  const DetallesEvaluacionScreen({
    super.key,
    required this.dimensionesPromedios,
    required this.empresa,
    required this.evaluacionId,
    required Map promedios,
  });

  @override
  State<DetallesEvaluacionScreen> createState() => _DetallesEvaluacionScreenState();
}

class _DetallesEvaluacionScreenState extends State<DetallesEvaluacionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.dimensionesPromedios.keys.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimensiones = widget.dimensionesPromedios.keys.toList();

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Detalles de Evaluación',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 35, 47, 112),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.menu,
              color: Colors.white,
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('Botón presionado');
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kTextTabBarHeight),
          child: Center(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: dimensiones.map((d) => Tab(text: d)).toList(),
              indicatorSize: TabBarIndicatorSize.label,
              labelPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ),
      endDrawer: const DrawerLensys(),
      body: TabBarView(
        controller: _tabController,
        children: dimensiones.map((d) {
          final promedios = widget.dimensionesPromedios[d]!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.dashboard),
                    label: const Text('Ver Dashboard'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DashboardScreen(
                            empresa: widget.empresa,
                            evaluacionId: widget.evaluacionId,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.file_download),
                    label: const Text('Generar Prereporte'),
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// Modelo y generador final para prereporte
class PrereporteDimension {
  final String dimension;
  final double promedioEjecutivo;
  final double promedioGerente;
  final double promedioMiembro;
  final double promedioGeneral;
  final Set<String> sistemasUnicos;

  PrereporteDimension({
    required this.dimension,
    required this.promedioEjecutivo,
    required this.promedioGerente,
    required this.promedioMiembro,
    required this.promedioGeneral,
    required this.sistemasUnicos,
  });
}

class PrereporteGeneratorFinal {
  static List<PrereporteDimension> generarDesde({
    required Map<String, Map<String, double>> promedios,
    required Map<String, Set<String>> sistemas,
  }) {
    final List<PrereporteDimension> lista = [];

    for (final dimension in promedios.keys) {
      final nivelData = promedios[dimension]!;
      final promedioEjecutivo = nivelData['Ejecutivo'] ?? 0;
      final promedioGerente = nivelData['Gerente'] ?? 0;
      final promedioMiembro = nivelData['Miembro'] ?? 0;
      final promedioGeneral = nivelData['General'] ?? 0;

      final sistemasUnicos = sistemas[dimension] ?? {};

      lista.add(
        PrereporteDimension(
          dimension: dimension,
          promedioEjecutivo: promedioEjecutivo,
          promedioGerente: promedioGerente,
          promedioMiembro: promedioMiembro,
          promedioGeneral: promedioGeneral,
          sistemasUnicos: sistemasUnicos,
        ),
      );
    }

    return lista;
  }
}