import 'package:flutter/material.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/services/evaluacion_cache_service.dart';

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

  const TablasDimensionScreen({super.key, required this.empresa, required this.evaluacionId, required String empresaId, required String dimension, required String asociadoId});

  static Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required int valor,
    required List<String> sistemas, required String dimensionId, required String asociadoId,
  }) async {
    final tablaDim = tablaDatos.putIfAbsent(dimension, () => {});
    final lista = tablaDim.putIfAbsent(evaluacionId, () => []);
    lista.add({
      'principio': principio,
      'comportamiento': comportamiento,
      'cargo': cargo.trim().capitalize(),
      'cargo_raw': cargo,
      'valor': valor,
      'sistemas': sistemas,
    });
    await EvaluacionCacheService().guardarTablas(tablaDatos);
    dataChanged.value = !dataChanged.value;
  }

  static void limpiarDatos() {
    tablaDatos.clear();
    dataChanged.value = false;
  }

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  late List<String> dimensiones;
  bool mostrarPromedio = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

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
    dimensiones = dimensionInterna.keys.toList();
  }

  String _normalizeNivel(String raw) {
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
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          leading: const BackButton(color: Colors.white),
          title: const Text('Resultados', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kTextTabBarHeight),
            child: Center(
              child: TabBar(
              indicatorColor: Colors.grey.shade300,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade300,
              isScrollable: true,
                tabs: dimensiones.map((d) => Tab(child: Center(child: Text(d)))).toList(),
              ),
            ),
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
                    onPressed: () => setState(() => mostrarPromedio = !mostrarPromedio),
                    child: Text(mostrarPromedio ? 'Ver sumas' : 'Promediar'),
                  ),
                  if (mostrarPromedio)
                    ElevatedButton(
                      onPressed: _irADetalles,
                      child: const Text('Ver detalles y avance'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: dimensiones.map((dimension) {
                  final keyInterna = dimensionInterna[dimension] ?? dimension;
                  final filas = TablasDimensionScreen.tablaDatos[keyInterna]
                          ?.values
                          .expand((l) => l)
                          .toList() ?? [];
                  if (filas.isEmpty) {
                    return const Center(child: Text('No hay datos para mostrar'));
                  }
                  return _buildDataTable(filas);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  void _irADetalles() {
    final promediosPorDimension = <String, Map<String, double>>{};
    for (final dim in dimensiones) {
      final keyInterna = dimensionInterna[dim] ?? dim;
      final filas = TablasDimensionScreen.tablaDatos[keyInterna]
              ?.values
              .expand((l) => l)
              .toList() ?? [];
      final sumasNivel = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosNivel = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasPromedio = SistemasPromedio();

      for (var f in filas) {
        final rawCargo = (f['cargo_raw'] as String?) ?? '';
        final nivel = _normalizeNivel(rawCargo);
        final valor = (f['valor'] as int?)?.toDouble() ?? 0.0;
        final sis = (f['sistemas'] as List?)?.whereType<String>().toList() ?? [];
        sumasNivel[nivel] = sumasNivel[nivel]! + valor;
        conteosNivel[nivel] = conteosNivel[nivel]! + 1;
        sistemasPromedio.agregar(nivel, sis);
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
          dimensionesPromedios: promediosPorDimension,
          empresa: widget.empresa,
          evaluacionId: widget.evaluacionId, promedios: {}, dimension: '',
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> filas) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        child: DataTable(
          columnSpacing: 20,
          headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          border: TableBorder.all(color: const Color(0xFF003056)),
          columns: [
            DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Ejecutivo', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Gerente', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Miembro', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Miembro Sistemas', style: TextStyle(color: Colors.white))),
          ],
          rows: _buildRows(filas),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> filas) {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorNivel = <String, Map<String, Map<String, Set<String>>>>{};

    for (var f in filas) {
      final principio = (f['principio'] as String?) ?? '';
      final comportamiento = (f['comportamiento'] as String?) ?? '';
      final rawCargo = (f['cargo_raw'] as String?) ?? '';
      final nivel = _normalizeNivel(rawCargo);
      final valor = (f['valor'] as int?) ?? 0;
      final sistemas = (f['sistemas'] as List<dynamic>?)?.whereType<String>().toList() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});

      sistemasPorNivel.putIfAbsent(principio, () => {});
      sistemasPorNivel[principio]!.putIfAbsent(comportamiento, () => {
        'Ejecutivo': <String>{},
        'Gerente':   <String>{},
        'Miembro':   <String>{},
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
          final cnt = cntMap[key]!;
          if (!mostrarPromedio || cnt == 0) return sumaMap[key]!.toString();
          return (sumaMap[key]! / cnt).toStringAsFixed(2);
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
/// Clase para almacenar y promediar los sistemas usados por nivel
class SistemasPromedio {
  final Map<String, Set<String>> _sistemasPorNivel = {
    'Ejecutivo': <String>{},
    'Gerente': <String>{},
    'Miembro': <String>{},
  };

  /// Agrega una lista de sistemas al nivel correspondiente
  void agregar(String nivel, List<String> sistemas) {
    final key = nivel.capitalize();
    if (_sistemasPorNivel.containsKey(key)) {
      _sistemasPorNivel[key]!.addAll(sistemas);
    }
  }

  /// Retorna el promedio de sistemas usados entre los 3 niveles
  double promedio() {
    final total = _sistemasPorNivel.values
        .fold<int>(0, (sum, set) => sum + set.length);
    return total / _sistemasPorNivel.length;
  }

  /// Retorna el conteo de sistemas por nivel
  Map<String, int> conteoPorNivel() {
    return _sistemasPorNivel.map((nivel, set) => MapEntry(nivel, set.length));
  }
}