import 'package:applensys/services/evaluacion_chart_data_final.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/dimension.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/comportamiento.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/charts/donut_chart.dart';
import 'package:applensys/charts/scatter_bubble_chart.dart';
import 'package:applensys/charts/grouped_bar_chart.dart';
import 'package:applensys/charts/horizontal_bar_systems_chart.dart';

class DashboardScreen extends StatefulWidget {
  final Empresa empresa;
  final String evaluacionId;

  const DashboardScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<Dimension>> _cargarDatos() async {
    final service = EvaluacionCacheService();
    await service.init();
    final tablas = await service.cargarTablas();

    final dimensionesList = <Map<String, dynamic>>[];

    for (final dim in tablas.entries) {
      final filas = dim.value[widget.evaluacionId] ?? [];
      if (filas.isEmpty) continue;

      final principiosMap = <String, List<Map<String, dynamic>>>{};
      for (final fila in filas) {
        final princ = fila['principio'] ?? 'SinPrincipio';
        principiosMap.putIfAbsent(princ, () => []).add(fila);
      }

      final principiosList = principiosMap.entries.map((e) {
        final comps = e.value.map((fila) {
          return {
            'nombre': fila['comportamiento'],
            'ejecutivo': fila['ejecutivo'],
            'gerente': fila['gerente'],
            'miembro': fila['miembro'],
            'sistemas': fila['sistemas'] ?? [],
            'nivel': fila['nivel'] ?? '',
          };
        }).toList();

        final prom = comps.fold(0.0, (s, f) =>
          s + (((f['ejecutivo'] ?? 0) + (f['gerente'] ?? 0) + (f['miembro'] ?? 0)) / 3.0),
        ) / comps.length;

        return {
          'nombre': e.key,
          'promedio': double.parse(prom.toStringAsFixed(2)),
          'comportamientos': comps,
        };
      }).toList();

      final promedioDimension = (filas.first['promedio_dimension'] ?? 0).toDouble();

      dimensionesList.add({
        'id': dim.key,
        'nombre': dim.key,
        'promedio': promedioDimension,
        'principios': principiosList,
      });
    }

    return EvaluacionChartData.buildDimensionesChartData(dimensionesList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Mueve el drawer al lado derecho
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        // Icono de back a la izquierda
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.empresa.nombre),
        // Icono de menú a la derecha que abre el drawer derecho
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Dimension>>(
        future: _cargarDatos(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final dimensiones = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildChartCard(
                title: 'Promedio por Dimensión',
                child: DonutChart(
                  data: {
                    for (final d in dimensiones) d.nombre: d.promedioGeneral
                  },
                  title: 'Promedio por Dimensión',
                ),
              ),
              _buildChartCard(
                title: 'Principios: Promedio vs. Nº Comportamientos',
                child: ScatterBubbleChart(
                  title: 'Principios',
                  data: _buildScatterData(dimensiones),
                ),
              ),
              _buildChartCard(
                title: 'Promedios por Comportamiento',
                child: GroupedBarChart(
                  data: _buildGroupedBarData(dimensiones),
                  title: 'Comportamientos',
                  minY: 0,
                  maxY: 5,
                ),
              ),
              _buildChartCard(
                title: 'Distribución por Nivel y Sistema',
                child: HorizontalBarSystemsChart(
                  data: _buildHorizontalBarData(dimensiones),
                  title: 'Sistemas',
                  minX: 0,
                  maxX: 5,
                  maxY: 0,
                  minY: 15,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(height: 300, child: child),
          ],
        ),
      ),
    );
  }

  List<ScatterData> _buildScatterData(List<Dimension> dims) {
    final principios = EvaluacionChartData.extractPrincipios(dims).cast<Principio>();
    return List.generate(principios.length, (i) {
      final p = principios[i];
      return ScatterData(
        x: i.toDouble(),
        y: p.promedioGeneral.clamp(0.0, 5.0),
        radius: p.comportamientos.length.toDouble(),
        color: Colors.blue,
      );
    });
  }

  Map<String, List<double>> _buildGroupedBarData(List<Dimension> dims) {
    final comps = EvaluacionChartData.extractComportamientos(dims).cast<Comportamiento>();
    return {
      for (final c in comps)
        c.nombre: [
          c.promedioEjecutivo.clamp(0, 5),
          c.promedioGerente.clamp(0, 5),
          c.promedioMiembro.clamp(0, 5),
        ]
    };
  }

  Map<String, Map<String, int>> _buildHorizontalBarData(List<Dimension> dims) {
    final data = <String, Map<String, int>>{};
    for (final d in dims) {
      for (final p in d.principios) {
        for (final c in p.comportamientos) {
          final sistemas = c.sistemas;
          for (final s in sistemas) {
            data.putIfAbsent(s, () => {'E': 0, 'G': 0, 'M': 0});
            final cargo = c.cargo;
            if (cargo == 'E' || cargo == 'G' || cargo == 'M') {
              data[s]![cargo] = (data[s]![cargo] ?? 0) + 1;
            }
          }
        }
      }
    }
    return data;
  }
}
