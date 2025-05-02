import 'package:applensys/models/empresa.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/drawer_lensys.dart';

class DetallesEvaluacionScreen extends StatefulWidget {
  /// Mapa de dimensiones a sus promedios por nivel (Ejecutivo, Gerente, Miembro, General)
  final Map<String, Map<String, double>> dimensionesPromedios;

  const DetallesEvaluacionScreen({
    super.key,
    required this.dimensionesPromedios, required Map promedios, required String dimension,
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
        title: const Text('Detalles de Evaluación'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: dimensiones.map((d) => Tab(text: d)).toList(),
        ),
      ),
      endDrawer: const DrawerLensys(),
      body: TabBarView(
        controller: _tabController,
        children: dimensiones.map((dimension) {
          final promedios = widget.dimensionesPromedios[dimension]!;
          return _buildDimensionDetails(context, dimension, promedios);
        }).toList(),
      ),
    );
  }

  Widget _buildDimensionDetails(
    BuildContext context,
    String dimension,
    Map<String, double> promedios,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPromedioGeneralCard(context, promedios),
        ],
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
              height: width * 0.4,
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
                        reservedSize: 28,
                        getTitlesWidget: _leftTitleWidget,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: _bottomTitleWidget,
                        reservedSize: 26,
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
                    radius: 26,
                    backgroundColor: _getColor(general),
                    child: Text(
                      general.toStringAsFixed(1),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
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
      barRods: [BarChartRodData(toY: y, color: color, width: 14, borderRadius: BorderRadius.circular(6))],
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    if (value % 1 == 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
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
