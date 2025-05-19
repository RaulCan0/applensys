
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
    required this.evaluacionId, required String dimension, required Map promedios,
  });

  @override
  State<DetallesEvaluacionScreen> createState() => _DetallesEvaluacionScreenState();
}

class _DetallesEvaluacionScreenState extends State<DetallesEvaluacionScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? selectedDimension;
  Map<String, dynamic>? selectedCalificaciones;

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
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detalles de Evaluación', style: TextStyle(color: Colors.white)),
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
          const SizedBox(height: 16),
          _buildDropdownAssociates(dimension),
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
  }

  Widget _buildPromedioGeneralCard(BuildContext context, Map<String, double> promedios) {
    final width = MediaQuery.of(context).size.width;
    final avgE = promedios['Ejecutivo'] ?? 0;
    final avgG = promedios['Gerente'] ?? 0;
    final avgM = promedios['Miembro'] ?? 0;
    final general = promedios['General'] ?? ((avgE + avgG + avgM) / 3);

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Promedios por Nivel',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160, // más pequeño
              child: BarChart(
                BarChartData(
                  maxY: 5,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  groupsSpace: 12,
                  barGroups: [
                    _buildBarGroup(0, avgE),
                    _buildBarGroup(1, avgG),
                    _buildBarGroup(2, avgM),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
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
            const SizedBox(height: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: _getColor(general),
              child: Text(
                general.toStringAsFixed(1),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 4),
            const Text('Promedio General de la Dimensión Calificada', style: TextStyle(fontSize: 14, fontFamily: 'Roboto')),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 14,
          color: _getColor(y),
          borderRadius: BorderRadius.circular(4),
        ),
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
        return const Text('Ejecutivo', style: TextStyle(fontSize: 10));
      case 1:
        return const Text('Gerente', style: TextStyle(fontSize: 10));
      case 2:
        return const Text('Equipo', style: TextStyle(fontSize: 10));
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getColor(double value) {
    if (value <= 0) return Colors.grey;
    if (value < 3) return Colors.red;
    if (value < 4) return Colors.amber;
    return Colors.green;
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
              icon: Icon(Icons.arrow_drop_down),
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
    return [
      // Aquí debes poner los datos reales, esto es un ejemplo.
      {'asociado_nombre': 'Juan Pérez', 'nivel': 'Ejecutivo', 'calificacion': 4, 'observacion': 'Buena actitud', 'sistemas_asociados': 'Sistema A'},
      {'asociado_nombre': 'Ana Gómez', 'nivel': 'Gerente', 'calificacion': 5, 'observacion': 'Excelente desempeño', 'sistemas_asociados': 'Sistema B'},
    ];
  }

  void _showCalificacionDetails(Map<String, dynamic> calificacion) {
    // Aquí se puede mostrar la vista detallada de la calificación
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Detalles de la Calificación de ${calificacion['asociado_nombre']}"),
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
}

/*import 'package:applensys/models/empresa.dart';
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
    required this.evaluacionId, required Map promedios, required String dimension,
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
          icon: const Icon(Icons.arrow_back),
          color: Colors.white,
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Detalles de Evaluación', style: TextStyle(color: Colors.white)),
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
  }

  Widget _buildPromedioGeneralCard(BuildContext context, Map<String, double> promedios) {
    final width = MediaQuery.of(context).size.width;
    final avgE = promedios['Ejecutivo'] ?? 0;
    final avgG = promedios['Gerente'] ?? 0;
    final avgM = promedios['Miembro'] ?? 0;
    final general = promedios['General'] ?? ((avgE + avgG + avgM) / 3);

   return Card(
  elevation: 3,
  margin: const EdgeInsets.all(8),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Promedios por Nivel',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 160, // más pequeño
          child: BarChart(
            BarChartData(
              maxY: 5,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              groupsSpace: 12,
              barGroups: [
                _buildBarGroup(0, avgE),
                _buildBarGroup(1, avgG),
                _buildBarGroup(2, avgM),
              ],
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
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
        const SizedBox(height: 12),
        CircleAvatar(
          radius: 18,
          backgroundColor: _getColor(general),
          child: Text(
            general.toStringAsFixed(1),
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        const Text('Promedio General de la Dimensión Calificada', style: TextStyle(fontSize: 14, fontFamily: 'Roboto')),

      ],
    ),
  ),
);
  }

BarChartGroupData _buildBarGroup(int x, double y) {
  return BarChartGroupData(
    x: x,
    barRods: [
      BarChartRodData(
        toY: y,
        width: 14,
        color: _getColor(y),
        borderRadius: BorderRadius.circular(4),
      ),
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
      return const Text('Ejecutivo', style: TextStyle(fontSize: 10));
    case 1:
      return const Text('Gerente', style: TextStyle(fontSize: 10));
    case 2:
      return const Text('Equipo', style: TextStyle(fontSize: 10));
    default:
      return const SizedBox.shrink();
  }
}

Color _getColor(double value) {
  if (value <= 0) return Colors.grey;
  if (value < 3) return Colors.red;
  if (value < 4) return Colors.amber;
  return Colors.green;
}
}
*/