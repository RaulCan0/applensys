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
late Future<List<Dimension>> _datosFuture;

@override
void initState() {
super.initState();
_datosFuture = _cargarDatos();
}

Future<List<Dimension>> _cargarDatos() async {
final service = EvaluacionCacheService();
await service.init();
final tablas = await service.cargarTablas();

final dimensionesList = <Dimension>[];

for (final dimEntry in tablas.entries) {
  final filas = dimEntry.value[widget.evaluacionId] ?? [];
  if (filas.isEmpty) continue;

  final principiosMap = <String, List<Map<String, dynamic>>>{};
  for (final fila in filas) {
    final princ = fila['principio']?.toString() ?? 'SinPrincipio';
    principiosMap.putIfAbsent(princ, () => []).add(fila);
  }

  final principiosList = <Principio>[];
  for (final entry in principiosMap.entries) {
    final compMap = <String, List<Map<String, dynamic>>>{};
    for (final fila in entry.value) {
      final comp = fila['comportamiento']?.toString() ?? 'SinComportamiento';
      compMap.putIfAbsent(comp, () => []).add(fila);
    }

    final comps = <Comportamiento>[];
    for (final ce in compMap.entries) {
      double sumaEj = 0, sumaGe = 0, sumaMi = 0;
      int countEj = 0, countGe = 0, countMi = 0;
      List<String> sistemas = [];
      String cargo = '';

      for (final fila in ce.value) {
        // parse valor seguro
        final raw = fila['valor'];
        double valor;
        if (raw is num) {
          valor = raw.toDouble();
        } else if (raw is String) {
          valor = double.tryParse(raw) ?? 0.0;
        } else {
          valor = 0.0;
        }

        // unifica clave cargo
        final cargoRaw = (fila['cargo'] as String? ?? fila['cargo_raw']?.toString() ?? '').toLowerCase();
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

        final sisList = fila['sistemas'];
        if (sisList is List) {
          sistemas.addAll(sisList.cast<String>());
        }
      }

      comps.add(
        Comportamiento(
          nombre: ce.key,
          promedioEjecutivo: countEj > 0 ? sumaEj / countEj : 0.0,
          promedioGerente: countGe > 0 ? sumaGe / countGe : 0.0,
          promedioMiembro: countMi > 0 ? sumaMi / countMi : 0.0,
          sistemas: sistemas.toSet().toList(),
          cargo: cargo,
        ),
      );
    }

    // cálculo promedio del principio
    double sumaProm = 0;
    int countProm = 0;
    for (final c in comps) {
      final proms = [
        c.promedioEjecutivo,
        c.promedioGerente,
        c.promedioMiembro
      ].where((v) => v > 0).toList();
      if (proms.isNotEmpty) {
        sumaProm += proms.reduce((a, b) => a + b) / proms.length;
        countProm++;
      }
    }
    final promedio = countProm > 0 ? sumaProm / countProm : 0.0;

    principiosList.add(
      Principio(
        id: entry.key,
        dimensionId: dimEntry.key,
        nombre: entry.key,
        promedioGeneral: promedio,
        comportamientos: comps,
      ),
    );
  }

  // promedio dimensión
  double sumaDim = 0;
  int countDim = 0;
  for (final p in principiosList) {
    if (p.promedioGeneral > 0) {
      sumaDim += p.promedioGeneral;
      countDim++;
    }
  }
  final promedioDimension = countDim > 0 ? sumaDim / countDim : 0.0;

  dimensionesList.add(
    Dimension(
      id: dimEntry.key,
      nombre: dimEntry.key,
      promedioGeneral: promedioDimension,
      principios: principiosList,
    ),
  );
}

if (dimensionesList.isEmpty) {
  return [
    // datos de prueba
    Dimension(
      id: '1',
      nombre: 'IMPULSORES CULTURALES',
      promedioGeneral: 3.5,
      principios: [
        Principio(
          id: 'P1',
          dimensionId: '1',
          nombre: 'Respetar a cada individuo',
          promedioGeneral: 3.5,
          comportamientos: [
            Comportamiento(
              nombre: 'Soporte',
              promedioEjecutivo: 4,
              promedioGerente: 3,
              promedioMiembro: 3.5,
              sistemas: ['Ambiental'],
              cargo: 'Ejecutivo',
            ),
          ],
        ),
      ],
    ),
  ];
}
return dimensionesList;

}

@override
Widget build(BuildContext context) {
return Scaffold(
endDrawer: const DrawerLensys(),
appBar: AppBar(
leading: IconButton(
icon: const Icon(Icons.arrow_back),
onPressed: () => Navigator.of(context).pop(),
),
title: Text(widget.empresa.nombre),
),
body: FutureBuilder<List<Dimension>>(
future: _datosFuture,
builder: (context, snapshot) {
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

      final dimensiones = snapshot.data!; // Now List<Dimension>
      return ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildChartCard(
            title: 'Promedio por Dimensión',
            child: DonutChart(
              data: {for (final d in dimensiones) d.nombre: d.promedioGeneral},
              title: 'Promedio por Dimensión',
            ),
          ),
          _buildChartCard(
            title: 'Principios',
            child: ScatterBubbleChart(
              data: [
                for (final p in dimensiones.expand((d) => d.principios))
                  ScatterData(
                    x: p.promedioGeneral,
                    y: p.comportamientos.length.toDouble(),
                    radius: (p.promedioGeneral * 8).clamp(10, 40), color: Colors.blue,
                  ),
              ],
              title: 'Principios',
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
              maxY: 5,
              minY: 0,
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

Map<String, List<double>> _buildGroupedBarData(List<Dimension> dims) {
final comps = dims.expand((d) => d.principios).expand((p) => p.comportamientos);
return {
for (final Comportamiento c in comps)
c.nombre: [
c.promedioEjecutivo.clamp(0, 5),
c.promedioGerente.clamp(0, 5),
c.promedioMiembro.clamp(0, 5),
]
};
}

Map<String, Map<String, double>> _buildHorizontalBarData(List<Dimension> dims) {
final sumMap = <String, Map<String, double>>{};
final countMap = <String, Map<String, int>>{};
for (final dim in dims) {
for (final pri in dim.principios) {
for (final comp in pri.comportamientos) {
for (final sistema in comp.sistemas) {
final nivel = comp.cargo == 'Ejecutivo' ? 'E'
: comp.cargo == 'Gerente' ? 'G'
: comp.cargo == 'Miembro' ? 'M' : '';
if (nivel.isEmpty) continue;
sumMap.putIfAbsent(sistema, () => {'E': 0.0, 'G': 0.0, 'M': 0.0});
countMap.putIfAbsent(sistema, () => {'E': 0, 'G': 0, 'M': 0});
double value;
if (nivel == 'E') {
  value = comp.promedioEjecutivo;
} else {
  value = nivel == 'G' ? comp.promedioGerente : comp.promedioMiembro;
}
sumMap[sistema]![nivel] = sumMap[sistema]![nivel]! + value;
countMap[sistema]![nivel] = countMap[sistema]![nivel]! + 1;
}
}
}
}
// calcular promedios finales
final avgMap = <String, Map<String, double>>{};
sumMap.forEach((sistema, niveles) {
avgMap[sistema] = {};
niveles.forEach((nivel, suma) {
final cnt = countMap[sistema]?[nivel] ?? 0;
avgMap[sistema]![nivel] = cnt > 0 ? (suma / cnt) : 0.0;
});
});
return avgMap;
}
}
