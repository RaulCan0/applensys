// lib/screens/detalles_evaluacion.dart

import 'package:applensys/models/empresa.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import '../widgets/drawer_lensys.dart';
import 'package:applensys/widgets/chat_screen.dart'; // Nueva importación

class DetallesEvaluacionScreen extends StatefulWidget {
  final Map<String, Map<String, double>> dimensionesPromedios;
  final Empresa empresa;
  final String evaluacionId;
  final String? dimension; // Hacerlo un campo de clase y opcional
  final int? initialTabIndex;

  const DetallesEvaluacionScreen({
    super.key,
    required this.dimensionesPromedios,
    required this.empresa,
    required this.evaluacionId,
    this.dimension,
    this.initialTabIndex, Map<String, double>? promedios,
  });

  @override
  State<DetallesEvaluacionScreen> createState() =>
      _DetallesEvaluacionScreenState();
}

class _DetallesEvaluacionScreenState extends State<DetallesEvaluacionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.dimensionesPromedios.keys.length,
      vsync: this,
      initialIndex: widget.initialTabIndex ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      // Left drawer con ancho fijo de 300
      drawer: SizedBox(width: 300, child: const DrawerLensys()),
      // Right drawer (endDrawer) con ancho por defecto
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Gráficos por Dimensión',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            color: Colors.white,
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(screenSize.height * 0.05),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            indicatorSize: TabBarIndicatorSize.label,
            tabs: widget.dimensionesPromedios.keys
                .map((key) => Tab(text: key))
                .toList(),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: widget.dimensionesPromedios.keys.map((dimension) {
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
    final screenSize = MediaQuery.of(context).size;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        vertical: screenSize.height * 0.05,
        horizontal: screenSize.width * 0.1,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPromedioGeneralCard(
            context,
            promedios,
            chartHeight: screenSize.height * 0.4,
            sidePadding: screenSize.width * 0.05,
          ),
          SizedBox(height: screenSize.height * 0.02),
          _buildDropdownAssociates(dimension),
          SizedBox(height: screenSize.height * 0.02),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF003056),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.leaderboard),
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
        ],
      ),
    );
  }

  Widget _buildPromedioGeneralCard(
    BuildContext context,
    Map<String, double> promedios, {
    double chartHeight = 150,
    double sidePadding = 90,
  }) {
    final screenSize = MediaQuery.of(context).size;

    final avgE = promedios['Ejecutivo'] ?? 0;
    final avgG = promedios['Gerente'] ?? 0;
    final avgM = promedios['Miembro'] ?? 0;

    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(vertical: screenSize.height * 0.02),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: screenSize.height * 0.02,
          horizontal: sidePadding,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Promedios por Cargo',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: screenSize.height * 0.01),
            FractionallySizedBox(
              widthFactor: 1.0,
              child: SizedBox(
                height: chartHeight,
                child: BarChart(
                  BarChartData(
                    maxY: 5,
                    minY: 0,
                    alignment: BarChartAlignment.spaceAround,
                    groupsSpace: 8,
                    barGroups: [
                      _buildBarGroup(0, avgE, Colors.orange),
                      _buildBarGroup(1, avgG, Colors.green),
                      _buildBarGroup(2, avgM, Colors.blue),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: screenSize.width * 0.05,
                          getTitlesWidget: _leftTitleWidget,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: screenSize.height * 0.05,
                          getTitlesWidget: _bottomTitleWidget,
                        ),
                      ),
                      topTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles:
                          const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    gridData: FlGridData(show: true, horizontalInterval: 1),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            SizedBox(height: screenSize.height * 0.02),
            _buildColorBar(avgE, avgG, avgM),
          ],
        ),
      ),
    );
  }

  Widget _buildColorBar(double ejecutivo, double gerente, double miembro) {
    const total = 5.0;
    final ejecutivoWidth = (ejecutivo / total).clamp(0.0, 1.0);
    final gerenteWidth = (gerente / total).clamp(0.0, 1.0);
    final miembroWidth = (miembro / total).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBarSegment(Colors.orange, ejecutivoWidth, ejecutivo),
        const SizedBox(height: 8),
        _buildBarSegment(Colors.green, gerenteWidth, gerente),
        const SizedBox(height: 8),
        _buildBarSegment(Colors.blue, miembroWidth, miembro),
      ],
    );
  }

  Widget _buildBarSegment(Color color, double percent, double value) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Container(
            width: constraints.maxWidth,
            height: 16,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              // Quitar el borderRadius
              // borderRadius: BorderRadius.circular(6),
            ),
          ),
          Container(
            width: constraints.maxWidth * percent,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              // Quitar el borderRadius
              // borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      );
    });
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 40,
          color: color,
          borderRadius: BorderRadius.all(Radius.circular(2)), // <-- Sin radio en las barras del gráfico
        ),
      ],
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    if (value % 1 == 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Text(value.toInt().toString(),
            style: const TextStyle(fontSize: 12)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _bottomTitleWidget(double value, TitleMeta meta) {
    switch (value.toInt()) {
      case 0:
        return const Text('Ejecutivo', style: TextStyle(fontSize: 12));
      case 1:
        return const Text('Gerente', style: TextStyle(fontSize: 12));
      case 2:
        return const Text('Miembro de Equipo', style: TextStyle(fontSize: 12));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildDropdownAssociates(String dimension) {
    final calificaciones = _getCalificacionesByDimension(dimension);

    return Column(
      children: calificaciones.map<Widget>((calificacion) {
        return Card(
          child: ListTile(
            title: Text("Asociado: ${calificacion['asociado_nombre']}"),
            subtitle: Text("Nivel: ${calificacion['nivel']}"),
            trailing: IconButton(
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: () {
                _showCalificacionDetails(calificacion);
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getCalificacionesByDimension(String dimension) {
    return [];
  }

  void _showCalificacionDetails(Map<String, dynamic> calificacion) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              "Detalles de la Calificación de ${calificacion['asociado_nombre']}"),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Nivel: ${calificacion['nivel']}"),
              Text("Calificación: ${calificacion['calificacion']}"),
              Text("Observación: ${calificacion['observacion']}"),
              Text("Sistemas asociados: ${calificacion['sistemas_asociados']}"),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
