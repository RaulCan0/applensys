import 'dart:developer';

import 'package:applensys/models/behavior_scroll_chart.dart';
import 'package:applensys/utils/dashboard_mock_data.dart';
import 'package:applensys/widgets/chart_widgets.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/level_averages.dart' as models;
import '../models/empresa.dart';
import '../services/supabase_service.dart';
import 'package:fl_chart/fl_chart.dart';

import '../services/excel_exporter.dart';

class DashboardScreen extends StatefulWidget {
  final Empresa? empresa;
  final int? dimensionId;
  final String evaluacionId;

  const DashboardScreen({super.key, this.empresa, this.dimensionId, required this.evaluacionId});

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
      _dimAverages = await svc.getDimensionAverages(widget.empresa!.id);
      _lineAverages = await svc.getLevelLineData(widget.empresa!.id);
      _princAverages = await svc.getPrinciplesAverages(widget.empresa!.id);
      _behavAverages = await svc.getBehaviorAverages(widget.empresa!.id);
      _sysAverages = await svc.getSystemAverages(widget.empresa!.id);
    } catch (_) {
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
        shape: const CircleBorder(),
        child: const Icon(Icons.download, color: Colors.black),
      ),
    );
  }

  Widget _buildTablet() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Column 1 (left)
            Container(
              width: MediaQuery.of(context).size.width * 0.3, // Adjusted width
              child: Column(
                children: [
                  Expanded(
                    child: _buildChartContainer(
                      data: _dimAverages,
                      builder: () => DimensionsDonutChart(
                        cultural: _dimAverages[0].general,
                        alignment: _dimAverages[1].general,
                        improvement: _dimAverages[2].general,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildChartContainer(
                      data: _lineAverages,
                      builder: () => MonthlyLineChart(
                        data: _lineAverages.map((e) => e.general).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Column 2 (center)
            Container(
              width: MediaQuery.of(context).size.width * 0.4, // Adjusted width
              child: Column(
                children: [
                  Expanded(
                    child: _buildChartContainer(
                      data: _princAverages,
                      builder: () => PrinciplesBubbleChart(
                        values: _princAverages.map((e) => e.general).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildChartContainer(
                      data: _behavAverages,
                      builder: () => BehaviorsGroupedBarChart(
                        values: _behavAverages.map((e) => e.general).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildChartContainer(
                      data: _behavAverages,
                      builder: () => BehaviorsScrollChart(
                        data: _behavAverages.map((e) => e.general).toList(), title: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Column 3 (right)
            Container(
              width: MediaQuery.of(context).size.width * 0.3, // Adjusted width
              child: Column(
                children: [
                  Expanded(
                    child: _buildChartContainer(
                      data: _sysAverages,
                      builder: () => SystemsVerticalBarChart(
                        values: _sysAverages.map((e) => e.general).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _buildChartContainer(
                      data: _princAverages,
                      builder: () => RadarChartWidget(
                        values: _princAverages.map((e) => e.general).toList(),
                      ),
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

  Widget _buildMobile() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _dimAverages,
            builder: () => DimensionsDonutChart(
              cultural: _dimAverages[0].general,
              alignment: _dimAverages[1].general,
              improvement: _dimAverages[2].general,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _lineAverages,
            builder: () => MonthlyLineChart(
              data: _lineAverages.map((e) => e.general).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _princAverages,
            builder: () => PrinciplesBubbleChart(
              values: _princAverages.map((e) => e.general).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _behavAverages,
            builder: () => BehaviorsGroupedBarChart(
              values: _behavAverages.map((e) => e.general).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _behavAverages,
            builder: () => BehaviorsScrollChart(
              data: _behavAverages.map((e) => e.general).toList(), title: '',
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _sysAverages,
            builder: () => SystemsVerticalBarChart(
              values: _sysAverages.map((e) => e.general).toList(),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: _buildChartContainer(
            data: _princAverages,
            builder: () => RadarChartWidget(
              values: _princAverages.map((e) => e.general).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
