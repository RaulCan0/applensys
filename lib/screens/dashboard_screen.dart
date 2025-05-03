// dashboard_screen.dart (corregido para evitar ScaffoldMessenger en initState)

import 'package:applensys/charts/behavior_scroll_chart.dart';
import 'package:applensys/charts/donut_chart.dart';
import 'package:applensys/charts/grouped_bar_chart.dart';
import 'package:applensys/charts/horizontal_bar_systems_chart.dart';
import 'package:applensys/charts/line_chart_sample.dart';
import 'package:applensys/charts/scatter_bubble_chart.dart' show ScatterBubbleChart;
import 'package:applensys/charts/radar_chart.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/level_averages.dart' as models;
import '../models/empresa.dart';
import '../services/supabase_service.dart';
import '../services/excel_exporter.dart';
import 'package:applensys/charts/scatter_bubble_chart.dart' show ScatterBubbleData;

class DashboardScreen extends StatefulWidget {
  final Empresa? empresa;
  final int? dimensionId;

  const DashboardScreen({super.key, this.empresa, this.dimensionId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<models.LevelAverages> _dimAverages = [];
  List<models.LevelAverages> _lineAverages = [];
  List<models.LevelAverages> _princAverages = [];
  List<models.LevelAverages> _behavAverages = [];
  List<models.LevelAverages> _sysAverages = [];

  @override
  void initState() {
    super.initState();
    _loadAllData(silent: true);
  }

  Future<void> _loadAllData({bool silent = false}) async {
    setState(() => _isLoading = true);
    final svc = SupabaseService();
    try {
      _dimAverages   = await svc.getDimensionAverages(widget.empresa!.id as int);
      _lineAverages  = await svc.getLevelLineData(widget.empresa!.id as int);
      _princAverages = await svc.getPrinciplesAverages(widget.empresa!.id as int);
      _behavAverages = await svc.getBehaviorAverages(widget.empresa!.id as int);
      _sysAverages   = await svc.getSystemAverages(widget.empresa!.id as int);
    } catch (_) {
      _dimAverages   = await svc.getLocalDimensionAverages();
      _lineAverages  = await svc.getLocalLevelLineData();
      _princAverages = await svc.getLocalPrinciplesAverages();
      _behavAverages = await svc.getLocalBehaviorAverages();
      _sysAverages   = await svc.getLocalSystemAverages();

      if (!silent && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Offline: cargando datos locales')),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportExcel() async {
    try {
      final file = await ExcelExporter.export(
        behaviorAverages: _behavAverages,
        systemAverages: _sysAverages,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel generado: ${file.path}')),
      );
        } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar Excel: $e')),
      );
        }
  }

  Widget _buildChartContainer({
    required List<dynamic> data,
    required Widget Function() builder,
  }) {
    if (data.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Text('Sin datos', style: TextStyle(color: Colors.grey)),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: builder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.dimensionId != null
        ? 'Dashboard Dimensión ${widget.dimensionId}'
        : 'Dashboard General';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAllData)],
      ),
      drawer: const DrawerLensys(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, bc) =>
                  bc.maxWidth >= 800 ? _buildTablet() : _buildMobile(),
            ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Exportar a Excel',
        onPressed: _exportExcel,
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildTablet() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildChartContainer(
                    data: _dimAverages,
                    builder: () => DonutChart(
                      data: DashboardChartAdapter.toDonutChartData(_dimAverages),
                      title: '3 Dimensiones',
                      min: 0,
                      max: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildChartContainer(
                    data: _lineAverages,
                    builder: () => LineChartSample(
                      data: _lineAverages,
                      title: 'Ejecutivo / Gerente / Miembro',
                      minY: 0,
                      maxY: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                Expanded(
                  child: _buildChartContainer(
                    data: _princAverages,
                    builder: () => ScatterBubbleChart(
                      data: DashboardChartAdapter.toScatterBubbleData(_princAverages),
                      title: '10 Principios',
                      minValue: 0,
                      maxValue: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildChartContainer(
                    data: _behavAverages,
                    builder: () => GroupedBarChart(
                      data: _behavAverages,
                      title: '28 Comportamientos',
                      minY: 0,
                      maxY: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildChartContainer(
                    data: DashboardChartAdapter.toScatterBubbleData(_behavAverages),
                    builder: () => BehaviorsScrollChart(
                      data: DashboardChartAdapter.toScatterBubbleData(_behavAverages),
                      title: 'Scroll por Principios',
                      minY: 0,
                      maxY: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: _buildChartContainer(
                    data: _sysAverages,
                    builder: () => HorizontalBarSystemsChart(
                      data: _sysAverages,
                      title: 'Sistemas Asociados',
                      min: 0,
                      max: 5, minY: 0, maxY: 5,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _buildChartContainer(
                    data: _princAverages,
                    builder: () => RadarChartWidget(
                      data: _princAverages,
                      title: 'Radar Principios',
                      min: 0,
                      max: 5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _dimAverages,
            builder: () => DonutChart(
              data: DashboardChartAdapter.toDonutChartData(_dimAverages),
              title: '3 Dimensiones',
              min: 0,
              max: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _lineAverages,
            builder: () => LineChartSample(
              data: _lineAverages,
              title: 'Ejecutivo / Gerente / Miembro',
              minY: 0,
              maxY: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _princAverages,
            builder: () => ScatterBubbleChart(
              data: DashboardChartAdapter.toScatterBubbleData(_princAverages),
              title: '10 Principios',
              minValue: 0,
              maxValue: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _behavAverages,
            builder: () => GroupedBarChart(
              data: _behavAverages,
              title: '28 Comportamientos',
              minY: 0,
              maxY: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: DashboardChartAdapter.toScatterBubbleData(_behavAverages),
            builder: () => BehaviorsScrollChart(
              data: DashboardChartAdapter.toScatterBubbleData(_behavAverages),
              title: 'Scroll por Principios',
              minY: 0,
              maxY: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _sysAverages,
            builder: () => HorizontalBarSystemsChart(
              data: _sysAverages,
              title: 'Sistemas Asociados',
              minY: 0,
              maxY: 5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _princAverages,
            builder: () => RadarChartWidget(
              data: _princAverages,
              title: 'Radar Principios',
              min: 0,
              max: 5,
            ),
          ),
        ),
      ],
    );
  }
}

class DashboardChartAdapter {
  static List<DonutChartData> toDonutChartData(List<models.LevelAverages> list) {
    return list.map((e) => DonutChartData(label: e.nombre, value: e.general)).toList();
  }

  static List<ScatterBubbleData> toScatterBubbleData(List<models.LevelAverages> list) {
    return list.map((e) => ScatterBubbleData(x: e.id.toDouble(), y: e.general)).toList();
  }

  static List<double> toRadarValues(List<models.LevelAverages> list) {
    return list.map((e) => e.general).toList();
  }

  static List<String> toRadarLabels(List<models.LevelAverages> list) {
    return list.map((e) => e.nombre).toList();
  }
}

class DonutChartData {
  final String label;
  final double value;
  DonutChartData({required this.label, required this.value});
}

// Removed duplicate ScatterBubbleData class definition to avoid conflicts.
