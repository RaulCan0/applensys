import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'tablas_screen.dart';

class DetallesEvaluacionScreen extends StatefulWidget {
  final String dimension;
  final Map<String, double> promedios;

  const DetallesEvaluacionScreen({
    super.key,
    required this.dimension,
    required this.promedios,
  });

  @override
  State<DetallesEvaluacionScreen> createState() => _DetallesEvaluacionScreenState();
}

class _DetallesEvaluacionScreenState extends State<DetallesEvaluacionScreen> {
  @override
  Widget build(BuildContext context) {
    final datos = TablasDimensionScreen.tablaDatos[widget.dimension] as List<Map<String, dynamic>>? ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalle de ${widget.dimension}'),
        backgroundColor: Colors.indigo,
      ),
      body: datos.isEmpty
          ? const Center(child: Text('No hay datos para esta dimensión'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPromedioGeneralCard(context),
                  const SizedBox(height: 16),
                  const Text(
                    'Detalle por Comportamiento',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...datos.map(_buildDetalleComportamientoCard),
                ],
              ),
            ),
    );
  }

  Widget _buildPromedioGeneralCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

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
              height: width * 0.4, // 🔥 MÁS PEQUEÑO Y RESPONSIVE
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.center,
                  maxY: 5,
                  minY: 0,
                  groupsSpace: 8,
                  barGroups: [
                    _buildBarGroup(0, widget.promedios['Ejecutivo'] ?? 0, Colors.blue),
                    _buildBarGroup(1, widget.promedios['Gerente'] ?? 0, Colors.orange),
                    _buildBarGroup(2, widget.promedios['Miembro'] ?? 0, Colors.green),
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
                    backgroundColor: _getColor(widget.promedios['General'] ?? 0),
                    child: Text(
                      (widget.promedios['General'] ?? 0).toStringAsFixed(1),
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
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
        BarChartRodData(
          toY: y,
          color: color,
          width: 14, // 🔥 MÁS DELGADO
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }

  Widget _leftTitleWidget(double value, TitleMeta meta) {
    if (value % 1 == 0) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
      );
    }
    return const SizedBox();
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
    return const Text('');
  }

  Widget _buildDetalleComportamientoCard(Map<String, dynamic> fila) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fila['comportamiento'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildChip('Ejecutivo', fila['Ejecutivo']),
                _buildChip('Gerente', fila['Gerente']),
                _buildChip('Miembro', fila['Miembro']),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, dynamic valor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getColor(double.tryParse(valor.toString()) ?? 0),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            valor.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Color _getColor(double value) {
    if (value <= 0) return Colors.grey;
    if (value < 3) return Colors.red;
    if (value < 4) return Colors.amber;
    return Colors.green;
  }
}
