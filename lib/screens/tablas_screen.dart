import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:applensys/providers/app_provider.dart';
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
    required this.evaluacionId, required String empresaId, required String dimension,
  });

  @override
  State<TablasDimensionScreen> createState() => _TablasDimensionScreenState();
}

class _TablasDimensionScreenState extends State<TablasDimensionScreen> {
  final List<String> dimensiones = ['Dimensión 1', 'Dimensión 2', 'Dimensión 3'];
  bool mostrarPromedio = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
    _cargarDesdeProveedor();
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  Future<void> _cargarDesdeProveedor() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    await appProvider.loadTablaDatos(widget.empresa.id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 35, 47, 112),
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
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey,
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
                  final filas = appProvider.tablaDatos[dimension]?.values.expand((l) => l).toList() ?? [];
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
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final promediosPorDimension = <String, Map<String, double>>{};

    for (final dim in dimensiones) {
      final filas = appProvider.tablaDatos[dim]?.values.expand((l) => l).toList() ?? [];
      final sumasNivel = {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0};
      final conteosNivel = {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0};
      final sistemasPromedio = SistemasPromedio();

      for (var f in filas) {
        final rawCargo = (f['cargo_raw'] as String?) ?? '';
        final nivel = _normalizeNivel(rawCargo);
        final valor = (f['valor'] as num?)?.toDouble() ?? 0.0;
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
          empresa: widget.empresa,
          dimensionesPromedios: promediosPorDimension,
          evaluacionId: widget.evaluacionId,
          promedios: {},
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
          headingRowColor: WidgetStateProperty.all(const Color.fromARGB(255, 35, 47, 112)),
          dataRowColor: WidgetStateProperty.all(Colors.white),
          border: TableBorder.all(color: const Color.fromARGB(255, 35, 47, 112)),
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
          rows: _buildRows(filas),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(List<Map<String, dynamic>> filas) {
    return filas.map((fila) {
      return DataRow(
        cells: [
          DataCell(Text(fila['principio'] ?? '')),
          DataCell(Text(fila['comportamiento'] ?? '')),
          DataCell(Text('${fila['ejecutivo'] ?? ''}')),
          DataCell(Text('${fila['gerente'] ?? ''}')),
          DataCell(Text('${fila['miembro'] ?? ''}')),
          DataCell(Text('${fila['ejecutivo_sistemas'] ?? ''}')),
          DataCell(Text('${fila['gerente_sistemas'] ?? ''}')),
          DataCell(Text('${fila['miembro_sistemas'] ?? ''}')),
        ],
      );
    }).toList();
  }

  String _normalizeNivel(String raw) {
    final l = raw.toLowerCase();
    if (l.contains('ejecutivo')) return 'Ejecutivo';
    if (l.contains('gerente')) return 'Gerente';
    return 'Miembro';
  }
}

class SistemasPromedio {
  final Map<String, Set<String>> _sistemasPorNivel = {
    'Ejecutivo': <String>{},
    'Gerente': <String>{},
    'Miembro': <String>{},
  };

  void agregar(String nivel, List<String> sistemas) {
    if (_sistemasPorNivel.containsKey(nivel)) {
      _sistemasPorNivel[nivel]!.addAll(sistemas);
    }
  }

  double promedio() {
    final total = _sistemasPorNivel.values.fold<int>(0, (sum, set) => sum + set.length);
    return total / _sistemasPorNivel.length;
  }
}
