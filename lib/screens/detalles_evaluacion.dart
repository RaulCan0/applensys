import 'package:applensys/models/empresa.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import '../widgets/drawer_lensys.dart';

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
    required Map promedios, // <--- ESTE PARÁMETRO
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
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
        icon: const Icon(
          Icons.menu,
          color: Colors.white,
        ),
        onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
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
        children: dimensiones.map((dimension) {
          final promedios = widget.dimensionesPromedios[dimension]!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromedioGeneralCard(context, promedios),
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
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPromedioGeneralCard(BuildContext context, Map<String, double> promedios) {
    final width = MediaQuery.of(context).size.width;
    final avgE = promedios['Ejecutivo'] ?? 0;
    final avgG = promedios['Gerente'] ?? 0;
    final avgM = promedios['Miembro'] ?? 0;
    final general = promedios['General'] ?? ((avgE + avgG + avgM) / 3);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Promedios por Nivel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: width * 0.25,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: 5,
                  minY: 0,
                  groupsSpace: 8,
                  barGroups: [
                    _buildBarGroup(0, avgE, Colors.blue),
                    _buildBarGroup(1, avgG, Colors.orange),
                    _buildBarGroup(2, avgM, Colors.green),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: _leftTitleWidget,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        getTitlesWidget: _bottomTitleWidget,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(show: true, horizontalInterval: 1),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Promedio General',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getColor(general),
                    child: Text(
                      general.toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: y, color: color, width: 10, borderRadius: BorderRadius.circular(6)),
      ],
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    if (value % 1 == 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _bottomTitleWidget(double value, TitleMeta meta) {
    switch (value.toInt()) {
      case 0:
        return const Text('Eje.', style: TextStyle(fontSize: 10));
      case 1:
        return const Text('Ger.', style: TextStyle(fontSize: 10));
      case 2:
        return const Text('Mie.', style: TextStyle(fontSize: 10));
    }
    return const SizedBox.shrink();
  }

  Color _getColor(double value) {
    if (value <= 0) return Colors.grey;
    if (value < 3) return Colors.red;
    if (value < 4) return Colors.amber;
    return Colors.green;
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