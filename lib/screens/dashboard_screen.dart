import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/empresa.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  final Empresa? empresa;
  final int? dimensionId;

  const DashboardScreen({super.key, this.empresa, this.dimensionId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;
  bool isLoading = true;
  List<Map<String, dynamic>> resultados = [];

  final List<Color> colores = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.amber,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);
    _cargarResultados();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _cargarResultados() async {
    setState(() => isLoading = true);
    try {
      final data = await SupabaseService().getResultadosDashboard(
        empresaId: widget.empresa?.id,
        dimensionId:widget.dimensionId,
      );
      if (mounted) {
        setState(() => resultados = data);
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al cargar resultados: $e');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final titulo =
        widget.dimensionId != null
            ? 'Dashboard Dimensión ${widget.dimensionId}'
            : 'Dashboard General';

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(titulo, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarResultados,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Resumen', icon: Icon(Icons.dashboard)),
            Tab(text: 'Tendencia', icon: Icon(Icons.trending_up)),
            Tab(text: 'Comparativo', icon: Icon(Icons.compare_arrows)),
            Tab(text: 'Distribución', icon: Icon(Icons.pie_chart)),
            Tab(text: 'Detalles', icon: Icon(Icons.list)),
          ],
        ),
      ),
      drawer: DrawerLensys(
        empresa: widget.empresa,
        dimensionId: widget.dimensionId,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : resultados.isEmpty
              ? const Center(child: Text('No hay resultados para mostrar.'))
              : TabBarView(
                controller: _tabController,
                children: [
                  _buildResumenTab(),
                  _buildTendenciaTab(),
                  _buildComparativoTab(),
                  _buildDistribucionTab(),
                  _buildDetallesTab(),
                ],
              ),
    );
  }

  Widget _buildResumenTab() {
    double promedioGeneral = 0;
    if (resultados.isNotEmpty) {
      double suma = resultados.fold(
        0,
        (acc, item) => acc + (item['promedio'] ?? 0).toDouble(),
      );
      promedioGeneral = suma / resultados.length;
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Promedio General: ${promedioGeneral.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: resultados.length,
              itemBuilder: (_, index) {
                final item = resultados[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item['titulo'] ?? 'Sin título'),
                    trailing: Text(
                      (item['promedio'] ?? 0).toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: LinearProgressIndicator(
                      value: (item['promedio'] ?? 0) / 5.0,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getColorForValue((item['promedio'] ?? 0)),
                      ),
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

  Widget _buildTendenciaTab() {
    final data =
        resultados.asMap().entries.map((entry) {
          final index = entry.key.toDouble();
          final value = (entry.value['promedio'] ?? 0).toDouble();
          return FlSpot(index, value);
        }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tendencia por Dimensión',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(value.toInt().toString()),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < resultados.length) {
                          final titulo =
                              resultados[value.toInt()]['titulo'] ?? '';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              titulo.toString().replaceAll('Dimensión ', 'D'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                minY: 0,
                maxY: 5,
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    barWidth: 3,
                    color: Colors.blue,
                    belowBarData: BarAreaData(
                      show: true,
                      // ignore: deprecated_member_use
                      color: Colors.blue.withOpacity(0.2),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparativoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comparativo por Rol',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 5,
                barGroups:
                    resultados.asMap().entries.map((entry) {
                      final index = entry.key;
                      final result = entry.value;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: (result['promedio_ejecutivo'] ?? 0).toDouble(),
                            color: Colors.blue,
                            width: 15,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                          BarChartRodData(
                            toY: (result['promedio_gerente'] ?? 0).toDouble(),
                            color: Colors.orange,
                            width: 15,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                          BarChartRodData(
                            toY: (result['promedio_miembro'] ?? 0).toDouble(),
                            color: Colors.green,
                            width: 15,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < resultados.length) {
                          final titulo =
                              resultados[value.toInt()]['titulo'] ?? '';
                          return SideTitleWidget(
                            axisSide: meta.axisSide,
                            child: Text(
                              titulo.toString().replaceAll('Dimensión ', 'D'),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                ),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLeyenda('Ejecutivo', Colors.blue),
              const SizedBox(width: 16),
              _buildLeyenda('Gerente', Colors.orange),
              const SizedBox(width: 16),
              _buildLeyenda('Miembro', Colors.green),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeyenda(String texto, Color color) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 4),
        Text(texto),
      ],
    );
  }

  Widget _buildDistribucionTab() {
    final sections =
        resultados.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final value = (item['promedio'] ?? 0).toDouble();
          return PieChartSectionData(
            value: value,
            title: value.toStringAsFixed(1),
            radius: 80,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            color: colores[index % colores.length],
          );
        }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribución de Calificaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(touchCallback: (event, response) {}),
              ),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: resultados.length,
              itemBuilder: (_, index) {
                final item = resultados[index];
                return Container(
                  margin: const EdgeInsets.only(right: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        color: colores[index % colores.length],
                      ),
                      const SizedBox(width: 4),
                      Text(item['titulo'] ?? 'Sin título'),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: resultados.length,
      itemBuilder: (_, index) {
        final item = resultados[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['titulo'] ?? 'Sin título',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Divider(),
                _buildDetalleRow(
                  'Promedio General:',
                  (item['promedio'] ?? 0).toStringAsFixed(2),
                ),
                _buildDetalleRow(
                  'Ejecutivo:',
                  (item['promedio_ejecutivo'] ?? 0).toStringAsFixed(2),
                ),
                _buildDetalleRow(
                  'Gerente:',
                  (item['promedio_gerente'] ?? 0).toStringAsFixed(2),
                ),
                _buildDetalleRow(
                  'Miembro:',
                  (item['promedio_miembro'] ?? 0).toStringAsFixed(2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetalleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Color _getColorForValue(double value) {
    if (value >= 4.5) return Colors.green.shade800;
    if (value >= 4.0) return Colors.green;
    if (value >= 3.5) return Colors.lightGreen;
    if (value >= 3.0) return Colors.amber;
    if (value >= 2.5) return Colors.orange;
    if (value >= 2.0) return Colors.deepOrange;
    return Colors.red;
  }
}
