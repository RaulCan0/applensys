

import 'package:flutter/material.dart';
import 'detalles_evaluacion.dart';
import '../widgets/drawer_lensys.dart';

String obtenerNombreDimension(String id) {
  switch (id) {
    case '1':
      return 'Dimensión 1';
    case '2':
      return 'Dimensión 2';
    case '3':
      return 'Dimensión 3';
    default:
      return 'Dimensión Desconocida';
  }
}

class TablasDimensionScreen extends StatefulWidget {
  static final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  const TablasDimensionScreen({super.key, required this.empresaId});
  final String empresaId;

  static void actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
  }) {
    if (!tablaDatos.containsKey(dimension)) {
      tablaDatos[dimension] = {};
    }

    if (!tablaDatos[dimension]!.containsKey(evaluacionId)) {
      tablaDatos[dimension]![evaluacionId] = [];
    }

    final datos = tablaDatos[dimension]![evaluacionId]!;

    datos.add({
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo.trim().toLowerCase().capitalize(),
      'valor': valor,
    });

    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  bool mostrarPromedio = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          leading: BackButton(color: Colors.white),
          backgroundColor: Colors.indigo,
          title: const Text('Resultados', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.calculate, color: Colors.white),
              label: Text(
                mostrarPromedio ? "Ver Sumas" : "Promediar",
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: () {
                setState(() {
                  mostrarPromedio = !mostrarPromedio;
                });
              },
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Dimensión 1'),
              Tab(text: 'Dimensión 2'),
              Tab(text: 'Dimensión 3'),
            ],
          ),
        ),
        endDrawer: const DrawerLensys(empresa: null, dimensionId: null),
        body: TabBarView(
          children: [
            _TablaDimension(dimension: 'Dimensión 1', mostrarPromedio: mostrarPromedio),
            _TablaDimension(dimension: 'Dimensión 2', mostrarPromedio: mostrarPromedio),
            _TablaDimension(dimension: 'Dimensión 3', mostrarPromedio: mostrarPromedio),
          ],
        ),
      ),
    );
  }
}

class _TablaDimension extends StatelessWidget {
  final String dimension;
  final bool mostrarPromedio;

  const _TablaDimension({required this.dimension, required this.mostrarPromedio});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TablasDimensionScreen.dataChanged,
      builder: (context, _, __) {
        final datosPorEvaluacion = TablasDimensionScreen.tablaDatos[dimension]!;
        final datos = datosPorEvaluacion.values.expand((e) => e).toList();

        if (datos.isEmpty) {
          return const Center(child: Text('No hay datos para mostrar'));
        }

        final Map<String, Map<String, Map<String, int>>> sumas = {};
        final Map<String, Map<String, Map<String, int>>> conteos = {};

        for (var fila in datos) {
          final principio = fila['principio'] ?? 'Sin principio';
          final comportamiento = fila['comportamiento'] ?? 'Sin comportamiento';
          final cargo = (fila['cargo'] ?? 'Miembro').toString().trim().capitalize();
          final valor = (fila['valor'] ?? 0) as int;

          sumas.putIfAbsent(principio, () => {});
          sumas[principio]!.putIfAbsent(comportamiento, () => {
            'Ejecutivo': 0,
            'Gerente': 0,
            'Miembro': 0,
          });

          conteos.putIfAbsent(principio, () => {});
          conteos[principio]!.putIfAbsent(comportamiento, () => {
            'Ejecutivo': 0,
            'Gerente': 0,
            'Miembro': 0,
          });

          sumas[principio]![comportamiento]![cargo] =
              (sumas[principio]![comportamiento]![cargo] ?? 0) + valor;
          conteos[principio]![comportamiento]![cargo] =
              (conteos[principio]![comportamiento]![cargo] ?? 0) + 1;
        }

        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingRowColor: WidgetStateColor.resolveWith((states) => Colors.indigo.shade300),
              dataRowColor: WidgetStateColor.resolveWith((states) => Colors.white),
              border: TableBorder.all(color: Colors.indigo.shade200),
              columns: const [
                DataColumn(label: Text('Principio')),
                DataColumn(label: Text('Comportamiento')),
                DataColumn(label: Text('Ejecutivo')),
                DataColumn(label: Text('Gerente')),
                DataColumn(label: Text('Miembro')),
              ],
              rows: sumas.entries.expand((principioEntry) {
                final principio = principioEntry.key;
                final comps = principioEntry.value;
                return comps.entries.map((compEntry) {
                  final comportamiento = compEntry.key;
                  final suma = compEntry.value;
                  final conteo = conteos[principio]![comportamiento]!;

                  String calcular(String nivel) {
                    if (!mostrarPromedio) return '${suma[nivel] ?? 0}';
                    final sum = suma[nivel] ?? 0;
                    final count = conteo[nivel] ?? 0;
                    if (count == 0) return '0';
                    return (sum / count).toStringAsFixed(2);
                  }

                  return DataRow(cells: [
                    DataCell(Text(principio)),
                    DataCell(Text(comportamiento)),
                    DataCell(Text(calcular('Ejecutivo'))),
                    DataCell(Text(calcular('Gerente'))),
                    DataCell(Text(calcular('Miembro'))),
                  ]);
                });
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}
