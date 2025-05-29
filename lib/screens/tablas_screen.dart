import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/widgets/chat_scren.dart';
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
    required String empresaId,
    required String dimension,
    required String asociadoId,
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
        item['cargo_raw'] == cargo &&
        item['dimension_id'] == dimensionId &&
        item['asociado_id'] == asociadoId);

    if (indiceExistente != -1) {
      lista[indiceExistente]['valor'] = valor;
      lista[indiceExistente]['sistemas'] = sistemas;
    } else {
      lista.add({
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo.trim().capitalize(),
        'cargo_raw': cargo,
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

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  late List<String> dimensiones;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // MODIFICADO: Mapas para almacenar controladores por clave de dimensión interna
  final Map<String, ScrollController> _verticalControllers = {};
  final Map<String, ScrollController> _horizontalControllers = {};

  final Map<String, String> dimensionInterna = {
    'IMPULSORES CULTURALES': 'Dimensión 1',
    'MEJORA CONTINUA': 'Dimensión 2',
    'ALINEAMIENTO EMPRESARIAL': 'Dimensión 3',
  };

  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
    _initializeScrollControllers(); // Inicializar controladores
    _cargarDesdeCache();
  }

  // NUEVO: Método para inicializar los controladores de scroll
  void _initializeScrollControllers() {
    for (var keyInterna in dimensionInterna.values) {
      if (!_verticalControllers.containsKey(keyInterna)) {
        _verticalControllers[keyInterna] = ScrollController();
      }
      if (!_horizontalControllers.containsKey(keyInterna)) {
        _horizontalControllers[keyInterna] = ScrollController();
      }
    }
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    // MODIFICADO: Dispose de todos los controladores en los mapas
    for (var controller in _verticalControllers.values) {
      controller.dispose();
    }
    for (var controller in _horizontalControllers.values) {
      controller.dispose();
    }
    _verticalControllers.clear();
    _horizontalControllers.clear();
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

  String _normalizeNivel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('miembro')) return 'Miembro';
    if (lower.contains('gerente')) return 'Gerente';
    return 'Ejecutivo';
  }

  @override
  Widget build(BuildContext context) {
    dimensiones = dimensionInterna.keys.toList();
    final textColor = Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black;

    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          title: const Text('Resultados en tiempo real', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
                tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              ),
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            isScrollable: false,
            tabs: dimensiones.map((d) => Tab(child: Text(d))).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: Column(
          children: [
            // MODIFICADO: Se elimina el botón "Promediar/Ver sumas" y la lógica condicional
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Centrar el botón restante
                children: [
                    Builder( // Se mantiene el Builder para el contexto del botón
                      builder: (BuildContext buttonContext) {
                        return ElevatedButton(
                         style: ElevatedButton.styleFrom(
                           backgroundColor: const Color(0xFF003056),
                           foregroundColor: Colors.white,
                         ),
                          onPressed: () => _irADetalles(buttonContext),
                          child: const Text('Ver detalles y avance'),
                        );
                      }
                    ),
                ],
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
                  // MODIFICADO: Obtener y pasar los controladores correctos
                  final verticalCtrl = _verticalControllers[keyInterna];
                  final horizontalCtrl = _horizontalControllers[keyInterna];

                  // Asegurarse de que los controladores no sean nulos (deberían estar inicializados)
                  if (verticalCtrl == null || horizontalCtrl == null) {
                    // Esto no debería suceder si _initializeScrollControllers se llama correctamente.
                    // Como fallback, podrías crearlos aquí, pero es mejor asegurar la inicialización.
                    // Por ahora, asumimos que no son nulos.
                    return const Center(child: Text("Error: Scroll controllers not initialized"));
                  }
                  return _buildDataTable(filas, textColor, verticalCtrl, horizontalCtrl);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _irADetalles(BuildContext tabControllerContext) { 
    final currentIndex = DefaultTabController.of(tabControllerContext).index; 
    final dimensionActual = dimensiones[currentIndex];

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
      promediosNivel['General'] = sumasNivel.isNotEmpty ? double.parse((totalProm / sumasNivel.length).toStringAsFixed(2)) : 0.0;
      promediosNivel['Sistemas'] = double.parse(sistemasPromedio.promedio().toStringAsFixed(2));

      promediosPorDimension[dim] = promediosNivel;
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

  // MODIFICADO: _buildDataTable ahora acepta controladores como parámetros
  Widget _buildDataTable(List<Map<String, dynamic>> filas, Color textColor, ScrollController verticalController, ScrollController horizontalController) {
    return Semantics(
      label: 'Tabla de datos de evaluación por principios y roles',
      child: Scrollbar(
        controller: verticalController, // Usar controlador pasado
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: verticalController, // Usar controlador pasado
          scrollDirection: Axis.vertical,
          child: Scrollbar(
            controller: horizontalController, // Usar controlador pasado
            thumbVisibility: true,
            notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
            child: SingleChildScrollView(
              controller: horizontalController, // Usar controlador pasado
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.all(8),
              child: DataTable(
                columnSpacing: 36,
                headingRowColor: WidgetStateProperty.resolveWith((states) {
                  return Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey.shade800
                      : const Color(0xFF003056);
                }),
                dataRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                border: TableBorder.all(color: const Color(0xFF003056)),
                columns: const [
                  DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Ejecutivo', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Gerente', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Miembro', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Ejecutivo Sistemas', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Gerente Sistemas', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Miembro Sistemas', style: TextStyle(color: Colors.white))),
                ],
                rows: _buildRows(filas), // Asegúrate que _buildRows está correctamente definido y devuelve List<DataRow>
              ),
            ),
          ),
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
      final valor = (f['valor'] as int?) ?? 0; // Asegúrate que el tipo es correcto o convierte de forma segura
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

      sumas[principio]![comportamiento]![nivel] = (sumas[principio]![comportamiento]![nivel] ?? 0) + valor;
      conteos[principio]![comportamiento]![nivel] = (conteos[principio]![comportamiento]![nivel] ?? 0) + 1;
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
          final cnt = cntMap[key] ?? 0;
          final suma = sumaMap[key] ?? 0;
          if (cnt == 0) return '-';
          return (suma / cnt).toStringAsFixed(2);
        }

        Widget sysCell(String key) {
          final set = sysMap[key]!;
          if (set.isEmpty) return const Text('-', style: TextStyle(color: Color(0xFF003056)));
          return IntrinsicHeight(
            child: IntrinsicWidth(
              child: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                child: Text(
                  set.join(', '),
                  style: const TextStyle(color: Color(0xFF003056)),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
              ),
            ),
          );
        }

        rows.add(DataRow(cells: [
          DataCell(Text(p, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(c, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(valorCell('Ejecutivo'), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(valorCell('Gerente'), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(valorCell('Miembro'), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(sysCell('Ejecutivo')),
          DataCell(sysCell('Gerente')),
          DataCell(sysCell('Miembro')),
        ]));
      });
    });

    return rows;
  }
}

// AÑADIDO: Clase SistemasPromedio
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
    if (_sistemasPorNivel.isEmpty) return 0.0;
    final totalSistemas = _sistemasPorNivel.values.fold<int>(0, (sum, set) => sum + set.length);
    final numeroDeNivelesConSistemas = _sistemasPorNivel.values.where((set) => set.isNotEmpty).length;
    if (numeroDeNivelesConSistemas == 0) return 0.0;
    return totalSistemas / _sistemasPorNivel.length; 
  }

  Map<String, int> conteoPorNivel() {
    return _sistemasPorNivel.map((nivel, set) => MapEntry(nivel, set.length));
  }
}
