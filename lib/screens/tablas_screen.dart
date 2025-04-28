import 'package:flutter/material.dart';
import 'detalles_evaluacion.dart';

class TablasDimensionScreen extends StatefulWidget {
  static final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  const TablasDimensionScreen({super.key, required empresaId});

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

    final index = datos.indexWhere(
      (fila) => fila['principio'] == principio && fila['comportamiento'] == comportamiento,
    );

    if (index != -1) {
      var fila = datos[index];
      fila[cargo] = (fila[cargo] ?? 0) + valor;
      fila['conteo_$cargo'] = (fila['conteo_$cargo'] ?? 0) + 1;
    } else {
      final nuevaFila = {
        'principio': principio,
        'comportamiento': comportamiento,
        'Ejecutivo': cargo == 'Ejecutivo' ? valor : 0,
        'Gerente': cargo == 'Gerente' ? valor : 0,
        'Miembro': cargo == 'Miembro' ? valor : 0,
        'conteo_Ejecutivo': cargo == 'Ejecutivo' ? 1 : 0,
        'conteo_Gerente': cargo == 'Gerente' ? 1 : 0,
        'conteo_Miembro': cargo == 'Miembro' ? 1 : 0,
      };
      datos.add(nuevaFila);
    }

    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  void _promediarValores(String dimension) {
    final datosPorEvaluacion = TablasDimensionScreen.tablaDatos[dimension]!;
    for (var datos in datosPorEvaluacion.values) {
      for (var fila in datos) {
        if ((fila['conteo_Ejecutivo'] ?? 0) > 0) {
          fila['Ejecutivo'] = (fila['Ejecutivo'] / fila['conteo_Ejecutivo']).toStringAsFixed(2);
        } else {
          fila['Ejecutivo'] = '0';
        }

        if ((fila['conteo_Gerente'] ?? 0) > 0) {
          fila['Gerente'] = (fila['Gerente'] / fila['conteo_Gerente']).toStringAsFixed(2);
        } else {
          fila['Gerente'] = '0';
        }

        if ((fila['conteo_Miembro'] ?? 0) > 0) {
          fila['Miembro'] = (fila['Miembro'] / fila['conteo_Miembro']).toStringAsFixed(2);
        } else {
          fila['Miembro'] = '0';
        }
      }
    }

    TablasDimensionScreen.dataChanged.value = !TablasDimensionScreen.dataChanged.value;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promedios calculados exitosamente')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados por dimensión'),
          backgroundColor: Colors.indigo,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dimensión 1'),
              Tab(text: 'Dimensión 2'),
              Tab(text: 'Dimensión 3'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TablaDimension(dimension: 'Dimensión 1', onPromediar: _promediarValores),
            _TablaDimension(dimension: 'Dimensión 2', onPromediar: _promediarValores),
            _TablaDimension(dimension: 'Dimensión 3', onPromediar: _promediarValores),
          ],
        ),
      ),
    );
  }
}

class _TablaDimension extends StatelessWidget {
  final String dimension;
  final void Function(String dimension) onPromediar;

  const _TablaDimension({required this.dimension, required this.onPromediar});

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

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 24,
                    headingRowColor: WidgetStateColor.resolveWith((states) => Colors.indigo.shade100),
                    dataRowColor: WidgetStateColor.resolveWith((states) => Colors.grey.shade50),
                    border: TableBorder.all(color: Colors.indigo),
                    columns: const [
                      DataColumn(label: Text('Principio', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Comportamiento', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Ejecutivo', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Gerente', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Miembro', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: datos.map((fila) {
                      return DataRow(
                        cells: [
                          DataCell(Text(fila['principio'] ?? '')),
                          DataCell(Text(fila['comportamiento'] ?? '')),
                          DataCell(Text((fila['Ejecutivo'] ?? '0').toString())),
                          DataCell(Text((fila['Gerente'] ?? '0').toString())),
                          DataCell(Text((fila['Miembro'] ?? '0').toString())),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => onPromediar(dimension),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text('Promediar'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}


/*import 'package:flutter/material.dart';
import 'detalles_evaluacion.dart';

class TablasDimensionScreen extends StatefulWidget {
  static final Map<String, List<Map<String, dynamic>>> tablaDatos = {
    'Dimensión 1': [],
    'Dimensión 2': [],
    'Dimensión 3': [],
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  const TablasDimensionScreen({super.key, required empresaId});

  static void actualizarDato({
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
  }) {
    if (!tablaDatos.containsKey(dimension)) {
      tablaDatos[dimension] = [];
    }

    final datos = tablaDatos[dimension]!;

    final index = datos.indexWhere(
      (fila) => fila['principio'] == principio && fila['comportamiento'] == comportamiento,
    );

    if (index != -1) {
      var fila = datos[index];
      fila[cargo] = (fila[cargo] ?? 0) + valor;
      fila['conteo_$cargo'] = (fila['conteo_$cargo'] ?? 0) + 1;
    } else {
      final nuevaFila = {
        'principio': principio,
        'comportamiento': comportamiento,
        'Ejecutivo': cargo == 'Ejecutivo' ? valor : 0,
        'Gerente': cargo == 'Gerente' ? valor : 0,
        'Miembro': cargo == 'Miembro' ? valor : 0,
        'conteo_Ejecutivo': cargo == 'Ejecutivo' ? 1 : 0,
        'conteo_Gerente': cargo == 'Gerente' ? 1 : 0,
        'conteo_Miembro': cargo == 'Miembro' ? 1 : 0,
      };
      datos.add(nuevaFila);
    }

    dataChanged.value = !dataChanged.value;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.actualizarDato(
      dimension: 'Dimensión 1', // o la que corresponda
      principio: 'Buscar la perfeccion',
      comportamiento: 'Mentalidad',
      cargo: 'Ejecutivo', // Debe coincidir exactamente
      valor: 5,           // El valor real de la evaluación
    );
  }

  void _promediarValores(String dimension) {
    final datos = TablasDimensionScreen.tablaDatos[dimension]!;
    if (datos.isEmpty) return;

    double sumaEjecutivo = 0;
    int conteoEjecutivo = 0;
    double sumaGerente = 0;
    int conteoGerente = 0;
    double sumaMiembro = 0;
    int conteoMiembro = 0;

    for (var fila in datos) {
      sumaEjecutivo += (fila['Ejecutivo'] as num?) ?? 0;
      conteoEjecutivo += (fila['conteo_Ejecutivo'] as int?) ?? 0;
      sumaGerente += (fila['Gerente'] as num?) ?? 0;
      conteoGerente += (fila['conteo_Gerente'] as int?) ?? 0;
      sumaMiembro += (fila['Miembro'] as num?) ?? 0;
      conteoMiembro += (fila['conteo_Miembro'] as int?) ?? 0;
    }

    double promedioEjecutivo = conteoEjecutivo > 0 ? sumaEjecutivo / conteoEjecutivo : 0;
    double promedioGerente = conteoGerente > 0 ? sumaGerente / conteoGerente : 0;
    double promedioMiembro = conteoMiembro > 0 ? sumaMiembro / conteoMiembro : 0;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Promedios - Ejecutivo: ${promedioEjecutivo.toStringAsFixed(2)}, '
          'Gerente: ${promedioGerente.toStringAsFixed(2)}, '
          'Miembro: ${promedioMiembro.toStringAsFixed(2)}',
        ),
      ),
    );
  }

  void _irADetalles(BuildContext context, String dimension) {
    final datos = TablasDimensionScreen.tablaDatos[dimension]!;

    if (datos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay datos para mostrar en esta dimensión')),
      );
      return;
    }

    double promedioEjecutivo = datos
        .map((f) => double.tryParse(f['Ejecutivo'].toString()) ?? 0)
        .fold(0.0, (a, b) => a + b) / datos.length;
    double promedioGerente = datos
        .map((f) => double.tryParse(f['Gerente'].toString()) ?? 0)
        .fold(0.0, (a, b) => a + b) / datos.length;
    double promedioMiembro = datos
        .map((f) => double.tryParse(f['Miembro'].toString()) ?? 0)
        .fold(0.0, (a, b) => a + b) / datos.length;
    double promedioGeneral = (promedioEjecutivo + promedioGerente + promedioMiembro) / 3;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallesEvaluacionScreen(
          dimension: dimension,
          promedios: {
            'Ejecutivo': promedioEjecutivo,
            'Gerente': promedioGerente,
            'Miembro': promedioMiembro,
            'General': promedioGeneral,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resultados por dimensión'),
          backgroundColor: Colors.indigo,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dimensión 1'),
              Tab(text: 'Dimensión 2'),
              Tab(text: 'Dimensión 3'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TablaDimension(
              dimension: 'Dimensión 1',
              onPromediar: _promediarValores,
              onDetalle: _irADetalles,
            ),
            _TablaDimension(
              dimension: 'Dimensión 2',
              onPromediar: _promediarValores,
              onDetalle: _irADetalles,
            ),
            _TablaDimension(
              dimension: 'Dimensión 3',
              onPromediar: _promediarValores,
              onDetalle: _irADetalles,
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaDimension extends StatelessWidget {
  final String dimension;
  final void Function(String dimension) onPromediar;
  final void Function(BuildContext context, String dimension) onDetalle;

  const _TablaDimension({required this.dimension, required this.onPromediar, required this.onDetalle});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: TablasDimensionScreen.dataChanged,
      builder: (context, _, __) {
        final datos = TablasDimensionScreen.tablaDatos[dimension]!;

        if (datos.isEmpty) {
          return const Center(child: Text('No hay datos para mostrar'));
        }

        return Column(
          children: [
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 24,
                      headingRowColor: WidgetStateColor.resolveWith((states) => Colors.indigo.shade100),
                      dataRowColor: WidgetStateColor.resolveWith((states) => Colors.grey.shade50),
                      border: TableBorder.all(color: Colors.indigo),
                      columns: const [
                        DataColumn(label: Text('Principio', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Comportamiento', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Ejecutivo', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Gerente', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Miembro', style: TextStyle(fontWeight: FontWeight.bold))),
                      ],
                      rows: datos.map((fila) {
                        return DataRow(
                          cells: [
                            DataCell(Text(fila['principio'] ?? '')),
                            DataCell(Text(fila['comportamiento'] ?? '')),
                            DataCell(Text(fila['Ejecutivo'].toString())),
                            DataCell(Text(fila['Gerente'].toString())),
                            DataCell(Text(fila['Miembro'].toString())),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => onPromediar(dimension),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text('Promediar'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => onDetalle(context, dimension),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                    child: const Text('Ver Detalle'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}*/
