// tablas_dimension_screen.dart corregida y extendida

import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:flutter/material.dart';
import '../widgets/drawer_lensys.dart';
import '../services/supabase_service.dart';

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

  const TablasDimensionScreen({super.key, required String empresaId, required String dimension});

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

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  bool mostrarPromedio = false;
  final List<String> dimensiones = TablasDimensionScreen.tablaDatos.keys.toList();

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
                      onPressed: () async {
                        final promediosPorDimension = <String, Map<String, double>>{};
                        for (final dim in dimensiones) {
                          final filas = TablasDimensionScreen
                                  .tablaDatos[dim]?.values.expand((l) => l).toList() ?? [];
                          final keys = TablasDimensionScreen.tablaDatos[dim]?.keys;
                          final evaluacionId = (keys != null && keys.isNotEmpty) ? keys.first : null;

                          if (evaluacionId != null && filas.isNotEmpty) {
                            await SupabaseService().subirPromediosCompletos(
                              evaluacionId: evaluacionId,
                              dimension: dim,
                              filas: filas,
                            );
                          }

                          final sumasNivel = {
                            'Ejecutivo': 0.0,
                            'Gerente': 0.0,
                            'Miembro': 0.0,
                          };
                          final conteosNivel = {
                            'Ejecutivo': 0,
                            'Gerente': 0,
                            'Miembro': 0,
                          };
                          final sistemasPromedio = SistemasPromedio();

                          for (var f in filas) {
                            final nivel = (f['cargo'] as String).capitalize();
                            final valor = (f['valor'] as int).toDouble();
                            final sistemas =
                                (f['sistemas'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

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

                          promediosNivel['General'] =
                              double.parse((totalProm / sumasNivel.length).toStringAsFixed(2));
                          promediosNivel['Sistemas'] =
                              double.parse(sistemasPromedio.promedio().toStringAsFixed(2));

                          promediosPorDimension[dim] = promediosNivel;
                        }

                        if (!mounted) return;
                        Navigator.push(
                          // ignore: use_build_context_synchronously
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetallesEvaluacionScreen(
                              dimensionesPromedios: promediosPorDimension,
                              promedios: {},
                              dimension: '',
                            ),
                          ),
                        );
                      },
                      child: const Text('Ver Detalles'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dim) => _TablaResultados(dimension: dim)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaResultados extends StatelessWidget {
  final String dimension;

  const _TablaResultados({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TablasDimensionScreen.dataChanged,
      builder: (context, _, __) {
        final mapa = TablasDimensionScreen.tablaDatos[dimension] ?? {};
        final filas = mapa.values.expand((e) => e).toList();

        if (filas.isEmpty) {
          return const Center(child: Text('No hay datos disponibles'));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.indigo),
            headingTextStyle: const TextStyle(color: Colors.white),
            columns: const [
              DataColumn(label: Text('Principio')),
              DataColumn(label: Text('Comportamiento')),
              DataColumn(label: Text('Nivel')),
              DataColumn(label: Text('Valor')),
              DataColumn(label: Text('Sistemas')),
            ],
            rows: filas.map((fila) {
              return DataRow(cells: [
                DataCell(Text(fila['principio'] ?? '')),
                DataCell(Text(fila['comportamiento'] ?? '')),
                DataCell(Text(fila['cargo'] ?? '')),
                DataCell(Text(fila['valor'].toString())),
                DataCell(Text((fila['sistemas'] as List<dynamic>?)?.join(', ') ?? '')),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }
}

class SistemasPromedio {
  final Map<String, List<String>> _datos = {
    'Ejecutivo': [],
    'Gerente': [],
    'Miembro': [],
  };

  void agregar(String nivel, List<String> sistemas) {
    if (_datos.containsKey(nivel)) {
      _datos[nivel]!.addAll(sistemas);
    }
  }

  double promedio() {
    final total = _datos.values.fold<List<String>>([], (prev, list) => prev..addAll(list));
    final conteo = total.length;
    return conteo > 0 ? conteo / 3 : 0;
  }
}
