// lib/screens/dashboard_screen.dart
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/services/evaluacion_chart_data_final.dart';
import 'package:flutter/material.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/dimension.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/comportamiento.dart';
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
  late final Future<List<Dimension>> _datosFuture;

  @override
  void initState() {
    super.initState();
    _datosFuture = _cargarDatos();
  }

  Future<List<Dimension>> _cargarDatos() async {
    final service = EvaluacionCacheService();
    await service.init();
    final tablas = await service.cargarTablas();

    final dimensionesList = <Map<String, dynamic>>[];

    for (final dimEntry in tablas.entries) {
      final filas = dimEntry.value[widget.evaluacionId] ?? [];
      if (filas.isEmpty) continue;

      // Agrupar por principio
      final principiosMap = <String, List<Map<String, dynamic>>>{};
      for (final fila in filas) {
        final princ = fila['principio'] as String? ?? 'SinPrincipio';
        principiosMap.putIfAbsent(princ, () => []).add(fila);
      }

      // Construir lista de principios con sus comportamientos
      final principiosList = principiosMap.entries.map((e) {
        double sumaEj = 0, sumaGe = 0, sumaMi = 0;
        int countEj = 0, countGe = 0, countMi = 0;
        List<String> sistemas = [];
        String cargo = '';

        // Agrupar comportamientos
        final comps = <Map<String, dynamic>>[];
        for (final fila in e.value) {
          final valor = (fila['valor'] as num?)?.toDouble() ?? 0.0;
          final cargoRaw = (fila['cargo'] as String? ?? fila['cargo_raw'] as String? ?? '').toLowerCase();
          cargo = cargoRaw.contains('ejecutivo')
              ? 'Ejecutivo'
              : cargoRaw.contains('gerente')
                  ? 'Gerente'
                  : cargoRaw.contains('miembro')
                      ? 'Miembro'
                      : '';
          if (cargo == 'Ejecutivo') {
            sumaEj += valor;
            countEj++;
          } else if (cargo == 'Gerente') {
            sumaGe += valor;
            countGe++;
          } else if (cargo == 'Miembro') {
            sumaMi += valor;
            countMi++;
          }
          sistemas.addAll((fila['sistemas'] as List?)?.cast<String>() ?? []);

          comps.add({
            'nombre': fila['comportamiento'],
            'ejecutivo': countEj > 0 ? sumaEj / countEj : 0.0,
            'gerente': countGe > 0 ? sumaGe / countGe : 0.0,
            'miembro': countMi > 0 ? sumaMi / countMi : 0.0,
            'sistemas': sistemas.toSet().toList(),
            'cargo': cargo,
          });
        }

        // Calcular promedio del principio
        double sumaProm = 0;
        int countProm = 0;
        for (final c in comps) {
          final ej = c['ejecutivo'] as double;
          final ge = c['gerente'] as double;
          final mi = c['miembro'] as double;
          int cargo = 0;
          double suma = 0;
          if (ej > 0) {
            suma += ej;
            cargo++;
          }
          if (ge > 0) {
            suma += ge;
            cargo++;
          }
          if (mi > 0) {
            suma += mi;
            cargo++;
          }
          if (cargo > 0) {
            sumaProm += suma / cargo;
            countProm++;
          }
        }
        final promedio = countProm > 0 ? sumaProm / countProm : 0.0;

        return {
          'nombre': e.key,
          'promedio': double.parse(promedio.toStringAsFixed(2)),
          'comportamientos': comps,
        };
      }).toList();

      // Promedio de la dimensión
      double sumaDim = 0;
      int countDim = 0;
      for (final p in principiosList) {
        final prom = (p['promedio'] as num?)?.toDouble() ?? 0.0;
        if (prom > 0) {
          sumaDim += prom;
          countDim++;
        }
      }
      final promedioDimension = countDim > 0 ? sumaDim / countDim : 0.0;

      dimensionesList.add({
        'id': dimEntry.key,
        'nombre': dimEntry.key,
        'promedio': double.parse(promedioDimension.toStringAsFixed(2)),
        'principios': principiosList,
      });
    }

    return EvaluacionChartData.buildDimensionesChartData(dimensionesList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.of(context).pop()),
        title: Text(widget.empresa.nombre),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Dimension>>(
        future: _datosFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !(snapshot.hasData) || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No hay datos disponibles para mostrar',
                style: TextStyle(fontSize: 16),
              ),
            );
          }
          final dimensiones = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildChartCard(
                title: 'Promedio por Dimensión',
                child: DonutChart(
                  data: {for (var d in dimensiones) d.nombre: d.promedioGeneral},
                  title: 'Promedio por Dimensión',
                ),
              ),
              _buildChartCard(
                title: 'Principios',
                child: ScatterBubbleChart(
                  data: [
                    for (final p in EvaluacionChartData.extractPrincipios(dimensiones))
                      ScatterData(
                        name: p.nombre,
                        value: p.promedioGeneral,
                        x: p.promedioGeneral,
                        y: p.comportamientos.length.toDouble(),
                        radius: p.promedioGeneral * 5, color: Colors.blue, // color: null, // Or provide a default color e.g. Colors.blue
                      )
                  ],
                  title: 'Principios',
                  minX: 0,
                  maxX: 5,
                  minY: 0,
                  maxY: dimensiones.length.toDouble(),
                ),
              ),
              _buildChartCard(
                title: 'Comportamientos',
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
                  // ¡Aquí corregimos los ejes Y!
                  minY: 0,
                  maxY: 15, // o el número máximo de categorías
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  Map<String, List<double>> _buildGroupedBarData(List<Dimension> dims) {
    final comps = EvaluacionChartData.extractComportamientos(dims);
    return {
      for (var c in comps)
        c.nombre: [
          c.promedioEjecutivo.clamp(0, 5),
          c.promedioGerente.clamp(0, 5),
          c.promedioMiembro.clamp(0, 5),
        ],
    };
  }

  Map<String, Map<String, int>> _buildHorizontalBarData(List<Dimension> dims) {
    final sistemasMap = <String, Map<String, int>>{};
    for (var dim in dims) {
      for (var pri in dim.principios) {
        for (var comp in pri.comportamientos) {
          for (var sis in comp.sistemas) {
            sistemasMap.putIfAbsent(sis, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
            sistemasMap[sis]![comp.cargo] = (sistemasMap[sis]![comp.cargo] ?? 0) + 1;
          }
        }
      }
    }
    return sistemasMap;
  }
}
