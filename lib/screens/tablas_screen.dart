import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
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
  /// Datos en memoria: dimension -> evaluacionId -> lista de filas
  static final Map<String, Map<String, List<Map<String, dynamic>>>> tablaDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };
  /// Notificador para cambios en tablaDatos
  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  final Empresa empresa;
  final String dimension;
  final String evaluacionId;

  const TablasDimensionScreen({
    super.key,
    required this.empresa,
    required this.dimension,
    required this.evaluacionId, required String empresaId,
  });

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();

  /// Agrega un registro y notifica cambio
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
  void initState() {
    super.initState();
    _loadCachedData();
    TablasDimensionScreen.dataChanged.addListener(_saveAllCache);
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_saveAllCache);
    super.dispose();
  }

  /// Carga datos de cache (SharedPreferences) al iniciar
  Future<void> _loadCachedData() async {
    final prefs = await SharedPreferences.getInstance();
    for (var dim in dimensiones) {
      final key = 'tabla_${widget.evaluacionId}_$dim';
      final jsonStr = prefs.getString(key);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        try {
          final list = List<Map<String, dynamic>>.from(jsonDecode(jsonStr));
          TablasDimensionScreen.tablaDatos[dim]?[widget.evaluacionId] = list;
        } catch (_) {}
      }
    }
    setState(() {});
  }

  /// Guarda todo tablaDatos relevante en SharedPreferences
  Future<void> _saveAllCache() async {
    final prefs = await SharedPreferences.getInstance();
    for (var dim in dimensiones) {
      final lista = TablasDimensionScreen.tablaDatos[dim]?[widget.evaluacionId];
      if (lista != null) {
        final key = 'tabla_${widget.evaluacionId}_$dim';
        await prefs.setString(key, jsonEncode(lista));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: Colors.indigo,
          leading: const BackButton(color: Colors.white),
          title: Text('Resultados - ${widget.dimension}', style: const TextStyle(color: Colors.white)),
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
            // Botones de salvar y ver detalles/promedio...
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
                      onPressed: () {
                        final promediosPorDimension = <String, Map<String, double>>{};
                        for (final dim in dimensiones) {
                          final filas = TablasDimensionScreen.tablaDatos[dim]?[widget.evaluacionId] ?? [];
                          // ... cálculo de promedios como antes ...
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetallesEvaluacionScreen(
                              empresa: widget.empresa,
                              dimensionesPromedios: promediosPorDimension,
                              evaluacionId: widget.evaluacionId,
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
                children: dimensiones.map((dim) {
                  final filas = TablasDimensionScreen.tablaDatos[dim]?[widget.evaluacionId] ?? [];
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
    // ... tu implementación existente ...
    return [];
  }
}

// Clase de cálculo de sistemas promedio sin cambios
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

  Map<String, int> conteoPorNivel() =>
      _sistemasPorNivel.map((nivel, set) => MapEntry(nivel, set.length));
}
