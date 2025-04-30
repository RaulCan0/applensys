import 'package:flutter/material.dart';
import '../widgets/drawer_lensys.dart';

// Extensión para capitalizar cadenas
extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class TablasDimensionScreen extends StatefulWidget {
  /// Datos: dimensión → evaluaciónId → lista de filas
  static final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };
  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  const TablasDimensionScreen({super.key, required String dimension});

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();

  /// Agrega una nueva evaluación a la tabla
  static void actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas,
  }) {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);
    lista.add({
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo.trim().capitalize(),
      'valor': valor,
      'sistemas': sistemas,
    });
    dataChanged.value = !dataChanged.value;
  }
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  bool mostrarPromedio = false;
  final List<String> dimensiones = ['Dimensión 1', 'Dimensión 2', 'Dimensión 3'];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          leading: const BackButton(color: Colors.white),
          title: const Text('Resultados', style: TextStyle(color: Colors.white)),
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: dimensiones.map((d) => Tab(text: d)).toList(),
          ),
          actions: [
            IconButton(
              icon: Icon(
                mostrarPromedio ? Icons.functions : Icons.calculate,
                color: Colors.white,
              ),
              tooltip: mostrarPromedio ? 'Ver sumas' : 'Promediar',
              onPressed: () => setState(() => mostrarPromedio = !mostrarPromedio),
            ),
          ],
        ),
        endDrawer: const DrawerLensys(empresa: null, dimensionId: null),
        body: TabBarView(
          children: dimensiones.map((dimension) {
            final filas = TablasDimensionScreen.tablaDatos[dimension]
                    ?.values
                    .expand((lista) => lista)
                    .toList() ?? [];

            if (filas.isEmpty) {
              return const Center(child: Text('No hay datos para mostrar'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 20,
                headingRowColor: WidgetStateProperty.all(Colors.indigo.shade300),
                dataRowColor: WidgetStateProperty.all(Colors.white),
                border: TableBorder.all(color: Colors.indigo.shade200),
                columns: const [
                  DataColumn(label: Text('Principio')),
                  DataColumn(label: Text('Comportamiento')),
                  DataColumn(label: Text('Ejecutivo')),
                  DataColumn(label: Text('Gerente')),
                  DataColumn(label: Text('Miembro')),
                  DataColumn(label: Text('Ejecutivo Sistemas')),
                  DataColumn(label: Text('Gerente Sistemas')),
                  DataColumn(label: Text('Miembro Sistemas')),
                ],
                rows: _buildRows(filas),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> filas) {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorNivel = <String, Map<String, Map<String, Set<String>>>>{};

    for (var f in filas) {
      final principio = f['principio'] as String;
      final comportamiento = f['comportamiento'] as String;
      final nivelRaw = f['cargo'] as String;
      final nivel = nivelRaw.capitalize();
      final valor = f['valor'] as int;
      final sistemas = (f['sistemas'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(
        comportamiento,
        () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0},
      );
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(
        comportamiento,
        () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0},
      );
      sistemasPorNivel.putIfAbsent(principio, () => {});
      sistemasPorNivel[principio]!.putIfAbsent(
        comportamiento,
        () => {
          'Ejecutivo': <String>{},
          'Gerente': <String>{},
          'Miembro': <String>{},
        },
      );

      sumas[principio]![comportamiento]![nivel] =
          sumas[principio]![comportamiento]![nivel]! + valor;
      conteos[principio]![comportamiento]![nivel] =
          conteos[principio]![comportamiento]![nivel]! + 1;
      for (var s in sistemas) {
        sistemasPorNivel[principio]![comportamiento]![nivel]!.add(s);
      }
    }

    final rows = <DataRow>[];
    sumas.forEach((p, compMap) {
      compMap.forEach((c, sumaMap) {
        final cntMap = conteos[p]![c]!;
        final sysMap = sistemasPorNivel[p]![c]!;

        String valorCell(String key) {
          if (!mostrarPromedio) return sumaMap[key]!.toString();
          final cnt = cntMap[key]!;
          return cnt == 0 ? '0' : (sumaMap[key]! / cnt).toStringAsFixed(2);
        }

        String sysCell(String key) {
          final set = sysMap[key]!;
          return set.isEmpty ? '-' : set.join(', ');
        }

        rows.add(DataRow(cells: [
          DataCell(Text(p)),
          DataCell(Text(c)),
          DataCell(Text(valorCell('Ejecutivo'))),
          DataCell(Text(valorCell('Gerente'))),
          DataCell(Text(valorCell('Miembro'))),
          DataCell(Text(sysCell('Ejecutivo'))),
          DataCell(Text(sysCell('Gerente'))),
          DataCell(Text(sysCell('Miembro'))),
        ]));
      });
    });

    return rows;
  }
}
