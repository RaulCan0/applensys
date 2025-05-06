import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:flutter/material.dart';
import '../widgets/drawer_lensys.dart';
import '../models/empresa.dart';

// Extensión para capitalizar cadenas
extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class TablasDimensionScreen extends StatefulWidget {
  static final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };
  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  final Empresa empresa;

  const TablasDimensionScreen({super.key, required String dimension, required String empresaId, required this.empresa});

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool mostrarPromedio = false;
  final List<String> dimensiones = ['Dimensión 1', 'Dimensión 2', 'Dimensión 3'];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          leading: const BackButton(color: Colors.white),
          title: const Text('Resultados', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: dimensiones.map((d) => Tab(text: d)).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() {
                      mostrarPromedio = !mostrarPromedio;
                    }),
                    child: Text(mostrarPromedio ? 'Ver sumas' : 'Promediar'),
                  ),
                  if (mostrarPromedio)
                    ElevatedButton(
                      onPressed: () {
                        final promediosPorDimension = <String, Map<String, double>>{};
                        for (final dim in dimensiones) {
                          final filas = TablasDimensionScreen.tablaDatos[dim]?.values.expand((l) => l).toList() ?? [];

                          final sumasNivel = {
                            'Ejecutivo': 0.0,
                            'Gerente': 0.0,
                            'Miembro': 0.0
                          };
                          final conteosNivel = {
                            'Ejecutivo': 0,
                            'Gerente': 0,
                            'Miembro': 0
                          };
                          final sistemasPromedio = SistemasPromedio();

                          for (var f in filas) {
                            final nivel = (f['cargo'] as String).capitalize();
                            final valor = (f['valor'] as int).toDouble();
                            final sistemas = (f['sistemas'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

                            sumasNivel[nivel] = sumasNivel[nivel]! + valor;
                            conteosNivel[nivel] = conteosNivel[nivel]! + 1;
                            sistemasPromedio.agregar(nivel, sistemas);
                          }

                          final promediosNivel = <String, double>{};
                          double totalProm = 0;
                          sumasNivel.forEach((nivel, suma) {
                            final cnt = conteosNivel[nivel]!;
                            final prom = cnt > 0 ? suma / cnt : 0;
                            promediosNivel[nivel] = double.parse(prom.toStringAsFixed(2));
                            totalProm += prom;
                          });
                          promediosNivel['General'] = double.parse((totalProm / sumasNivel.length).toStringAsFixed(2));
                          promediosNivel['Sistemas'] = double.parse(sistemasPromedio.promedio().toStringAsFixed(2));

                          promediosPorDimension[dim] = promediosNivel;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetallesEvaluacionScreen(
                              empresa: widget.empresa,
                              dimensionesPromedios: promediosPorDimension,
                              evaluacionId: 'someEvaluacionId', // Replace with the actual evaluacionId
                            ),
                          ),
                        );
                      },
                      child: const Text('Ver detalles y avance'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dimension) {
                  final filas = TablasDimensionScreen.tablaDatos[dimension]?.values.expand((l) => l).toList() ?? [];
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
          ],
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
      final nivel = (f['cargo'] as String).capitalize();
      final valor = f['valor'] as int;
      final sistemas = (f['sistemas'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      sistemasPorNivel.putIfAbsent(principio, () => {});
      sistemasPorNivel[principio]!.putIfAbsent(comportamiento, () => {
        'Ejecutivo': <String>{},
        'Gerente': <String>{},
        'Miembro': <String>{},
      });

      sumas[principio]![comportamiento]![nivel] = sumas[principio]![comportamiento]![nivel]! + valor;
      conteos[principio]![comportamiento]![nivel] = conteos[principio]![comportamiento]![nivel]! + 1;
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
          return cnt == 0 ? '0' : (sumaMap[key]! / cnt).toString();
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

class SistemasPromedio {
  final Map<String, Set<String>> _sistemasPorNivel = {
    'Ejecutivo': <String>{},
    'Gerente': <String>{},
    'Miembro': <String>{},
  };

  void agregar(String nivel, List<String> sistemas) {
    final key = nivel.capitalize();
    if (_sistemasPorNivel.containsKey(key)) {
      _sistemasPorNivel[key]!.addAll(sistemas);
    }
  }

  double promedio() {
    final total = _sistemasPorNivel.values.fold<int>(0, (sum, set) => sum + set.length);
    return total / _sistemasPorNivel.length;
  }

  Map<String, int> conteoPorNivel() {
    return _sistemasPorNivel.map((nivel, set) => MapEntry(nivel, set.length));
  }
}
