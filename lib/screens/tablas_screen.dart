import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';

extension CapitalizeExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class TablasDimensionScreen extends StatefulWidget {
  static Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  final Empresa empresa;
  final String evaluacionId;

  const TablasDimensionScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
    required String asociadoId,
    required String empresaId,
    required String dimension,
  });

  static Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas,
    required String dimensionId,
    required String asociadoId,
  }) async {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);

    final indiceExistente = lista.indexWhere((item) =>
        item['principio'] == principio &&
        item['comportamiento'] == comportamiento &&
        item['cargo'] == cargo &&
        item['dimension_id'] == dimensionId &&
        item['asociado_id'] == asociadoId);

    if (indiceExistente != -1) {
      lista[indiceExistente]['valor'] = valor;
      lista[indiceExistente]['sistemas'] = sistemas;
    } else {
      lista.add({
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo,
        'valor': valor,
        'sistemas': sistemas,
        'dimension_id': dimensionId,
        'asociado_id': asociadoId,
      });
    }

    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
  }

  static Future<void> limpiarDatos() async {
    tablaDatos.clear();
    dataChanged.value = false;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> with TickerProviderStateMixin {
  final Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

  List<String> dimensiones = [];

  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
    _cargarDesdeCache();
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  Future<void> _cargarDesdeCache() async {
    final data = await EvaluacionCacheService().cargarTablas();
    if (data.values.any((m) => m.isNotEmpty)) {
      setState(() => TablasDimensionScreen.tablaDatos = data);
    }
    if (mounted) {
      setState(() {
        dimensiones = dimensionInterna.keys.toList();
      });
    }
  }

  String _normalizeCargo(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
    dimensiones = dimensionInterna.keys.toList();

    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          title: const Text('Resultados en tiempo real', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            tabs: dimensiones.map((d) => Tab(child: Text(d))).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Builder(
                  builder: (innerContext) => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003056),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _irADetalles(innerContext),
                    child: const Text('Ver detalles y avance'),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dimension) {
                  final keyInterna = dimensionInterna[dimension] ?? dimension;
                  final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

                  if (filas.isEmpty) {
                    return const Center(child: Text('No hay datos para mostrar para esta evaluación'));
                  }

                  return InteractiveViewer(
                    constrained: false,
                    scaleEnabled: false,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.all(8),
                        child: DataTable(
                          columnSpacing: 36,
                          headingRowColor: WidgetStateProperty.resolveWith(
                            (states) => Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey.shade800
                                : const Color(0xFF003056),
                          ),
                          dataRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                          border: TableBorder.all(color: const Color(0xFF003056)),
                          columns: const [
                            DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Cargo Ejecutivo', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Cargo Gerente', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Cargo Miembro', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
                            DataColumn(label: Text('Miembro Sistemas', style: TextStyle(color: Colors.white))),
                          ],
                          rows: _buildRows(filas),
                        ),
                      ),
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

  void _irADetalles(BuildContext context) {
    final currentIndex = DefaultTabController.of(context).index;
    final dimensionActual = dimensiones[currentIndex];

    final promediosPorDimension = <String, Map<String, double>>{};
    for (final dim in dimensiones) {
      final keyInterna = dimensionInterna[dim] ?? dim;
      final filas = TablasDimensionScreen.tablaDatos[keyInterna]?.values.expand((l) => l).toList() ?? [];

      final sumasCargo = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosCargo = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasPromedio = SistemasPromedio();

      for (var f in filas) {
        final cargo = _normalizeCargo(f['cargo'] ?? '');
        final valor = (f['valor'] ?? 0).toDouble();
        final sistemas = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
        sumasCargo[cargo] = sumasCargo[cargo]! + valor;
        conteosCargo[cargo] = conteosCargo[cargo]! + 1;
        sistemasPromedio.agregar(cargo, sistemas);
      }

      final promediosCargo = <String, double>{};
      double totalProm = 0;
      sumasCargo.forEach((cargo, suma) {
        final cnt = conteosCargo[cargo]!;
        final prom = cnt > 0 ? suma / cnt : 0;
        promediosCargo[cargo] = double.parse(prom.toStringAsFixed(2));
        totalProm += prom;
      });
      promediosCargo['General'] = double.parse((totalProm / sumasCargo.length).toStringAsFixed(2));
      promediosCargo['Sistemas'] = double.parse(sistemasPromedio.promedio().toStringAsFixed(2));
      promediosPorDimension[dim] = promediosCargo;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetallesEvaluacionScreen(
          dimensionesPromedios: promediosPorDimension,
          empresa: widget.empresa,
          evaluacionId: widget.evaluacionId,
          promedios: promediosPorDimension[dimensionActual],
          dimension: dimensionActual,
          initialTabIndex: currentIndex,
        ),
      ),
    );
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> filas) {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorCargo = <String, Map<String, Map<String, Set<String>>>>{};

    for (var f in filas) {
      final principio = f['principio'] ?? '';
      final comportamiento = f['comportamiento'] ?? '';
      final cargo = _normalizeCargo(f['cargo'] ?? '');  
      final int valor = ((f['valor'] ?? 0) as num).toInt();
      final sistemas = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      sistemasPorCargo.putIfAbsent(principio, () => {});
      sistemasPorCargo[principio]!.putIfAbsent(comportamiento, () => {
        'Ejecutivo': <String>{},
        'Gerente': <String>{},
        'Miembro': <String>{},
      });

      sumas[principio]![comportamiento]![cargo] = sumas[principio]![comportamiento]![cargo]! + valor;
      conteos[principio]![comportamiento]![cargo] = conteos[principio]![comportamiento]![cargo]! + 1;
      for (var s in sistemas) {
        sistemasPorCargo[principio]![comportamiento]![cargo]!.add(s);
      }
    }

    return sumas.entries.expand((e) {
      final p = e.key;
      return e.value.entries.map((cEntry) {
        final c = cEntry.key;
        final cargoVals = cEntry.value;
        final cargos = ['Ejecutivo', 'Gerente', 'Miembro'];
        return DataRow(cells: [
          DataCell(Text(p, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(c, style: const TextStyle(color: Color(0xFF003056)))),
          ...cargos.map((cg) {
            final suma = cargoVals[cg] ?? 0;
            final count = conteos[p]![c]![cg]!;
            return DataCell(Text(count > 0 ? (suma / count).toStringAsFixed(2) : '-', style: const TextStyle(color: Color(0xFF003056))));
          }),
          ...cargos.map((cg) {
            final sistemas = sistemasPorCargo[p]![c]![cg]!;
            return DataCell(Text(sistemas.isEmpty ? '-' : sistemas.join(', '), style: const TextStyle(color: Color(0xFF003056))));
          }),
        ]);
      });
    }).toList();
  }
}
class SistemasPromedio {
  final Map<String, Set<String>> _sistemasPorCargo = {
    'Ejecutivo': <String>{},
    'Gerente': <String>{},
    'Miembro': <String>{},
  };

  void agregar(String cargo, List<String> sistemas) {
    final key = cargo.capitalize();
    if (_sistemasPorCargo.containsKey(key)) {
      _sistemasPorCargo[key]!.addAll(sistemas);
    }
  }

  double promedio() {
    if (_sistemasPorCargo.isEmpty) return 0.0;
    final total = _sistemasPorCargo.values.fold<int>(0, (sum, set) => sum + set.length);
    final nonEmpty = _sistemasPorCargo.values.where((s) => s.isNotEmpty).length;
    return nonEmpty == 0 ? 0.0 : total / _sistemasPorCargo.length;
  }
}
