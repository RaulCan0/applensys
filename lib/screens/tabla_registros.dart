// lib/screens/tablas_registros.dart

import 'package:flutter/material.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/widgets/drawer_lensys.dart';

class TablasRegistrosScreen extends StatefulWidget {
  /// Datos en memoria: dimensión → evaluaciónId → lista de registros
  static Map<String, Map<String, List<Map<String, dynamic>>>> registrosDatos = {
    'Dimensión 1': {},
    'Dimensión 2': {},
    'Dimensión 3': {},
  };

  /// Notificador para reconstruir la UI al agregar un registro
  static final ValueNotifier<bool> dataChanged = ValueNotifier<bool>(false);

  final Empresa empresa;
  final String evaluacionId;

  const TablasRegistrosScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId, required String empresaId, required String asociadoId, required String dimension,
  });

  /// Agrega un nuevo registro (fila) a la tabla de la dimensión indicada
  static Future<void> actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String nivel,
    required String nombreAsociado,
    required int calificacion,
    required List<String> sistemasAsociados,
    required String observacion,
    required String evidencia,
  }) async {
    final dimMap = registrosDatos.putIfAbsent(dimension, () => {});
    final lista = dimMap.putIfAbsent(evaluacionId, () => []);
    lista.add({
      'principio': principio,
      'comportamiento': comportamiento,
      'nivel': nivel,
      'nombreAsociado': nombreAsociado,
      'calificacion': calificacion,
      'sistemasAsociados': sistemasAsociados,
      'observacion': observacion,
      'evidencia': evidencia,
    });
    // Guarda en caché
    await EvaluacionCacheService().guardarRegistros(registrosDatos);
    // Dispara la actualización de la UI
    dataChanged.value = !dataChanged.value;
  }

  /// Limpia todos los registros
  static Future<void> limpiarDatos() async {
    registrosDatos.clear();
    dataChanged.value = false;
    await EvaluacionCacheService().limpiarRegistros();
  }

  @override
  State<TablasRegistrosScreen> createState() => _TablasRegistrosScreenState();
}

class _TablasRegistrosScreenState extends State<TablasRegistrosScreen> {
  late List<String> dimensiones;
  final Map<String, String> _dimMap = {
    'Dimensión 1': 'Dimensión 1',
    'Dimensión 2': 'Dimensión 2',
    'Dimensión 3': 'Dimensión 3',
  };

  @override
  void initState() {
    super.initState();
    TablasRegistrosScreen.dataChanged.addListener(_onDataChanged);
    _cargarDesdeCache();
  }

  @override
  void dispose() {
    TablasRegistrosScreen.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() => setState(() {});

  Future<void> _cargarDesdeCache() async {
    final data = await EvaluacionCacheService().cargarRegistros();
    if (data.isNotEmpty) {
      setState(() => TablasRegistrosScreen.registrosDatos = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    dimensiones = _dimMap.keys.toList();
    return DefaultTabController(
      length: dimensiones.length,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF003056),
          leading: const BackButton(color: Colors.white),
          title: const Text('Registros Detallados', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          bottom: TabBar(
            indicatorColor: Colors.grey.shade300,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey.shade300,
            isScrollable: true,
            tabs: dimensiones.map((d) => Tab(text: d)).toList(),
          ),
        ),
        endDrawer: const DrawerLensys(),
        body: TabBarView(
          children: dimensiones.map((dim) {
            final filas = TablasRegistrosScreen
                    .registrosDatos[_dimMap[dim]]?[widget.evaluacionId] ??
                [];
            if (filas.isEmpty) {
              return const Center(child: Text('No hay registros'));
            }
            return _buildDataTable(filas);
            
          }).toList(),
        ),
        floatingActionButton: Builder(
          builder: (BuildContext fabContext) { // Usar Builder para obtener el contexto correcto
            return FloatingActionButton(
              onPressed: () {
                // Acceder al TabController usando el contexto del Builder
                final tabController = DefaultTabController.of(fabContext);
                final currentIndex = tabController.index;
                final currentDimensionKey = dimensiones[currentIndex];
                
                // ignore: avoid_print
                print('FAB presionado. Dimensión actual: $currentDimensionKey, Evaluación ID: ${widget.evaluacionId}');
                
                // Aquí iría la lógica para mostrar un diálogo o navegar
                // a una pantalla para crear un nuevo registro.
                // Se necesitarían todos los campos para llamar a:
                // TablasRegistrosScreen.actualizarDato(
                //   widget.evaluacionId,
                //   dimension: currentDimensionKey, 
                //   principio: "...";
                //   comportamiento: "...";
                //   nivel: "...";
                //   nombreAsociado: "...";
                //   calificacion: 0;
                //   sistemasAsociados: [];
                //   observacion: "...";
                //   evidencia: "...";
                // );

                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(content: Text('Añadir nuevo registro a: $currentDimensionKey (acción pendiente)')),
                );
              },
              backgroundColor: const Color(0xFF003056),
              tooltip: 'Añadir nuevo registro',
              child: const Icon(Icons.add, color: Colors.white),
            );
          }
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
          columnSpacing: 16,
          headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
          border: TableBorder.all(color: const Color(0xFF003056)),
          columns: const [
            DataColumn(label: Text('Principio', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Nivel', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Nombre Asociado', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Calificación', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Sistemas Asociados', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Observación', style: TextStyle(color: Colors.white))),
            DataColumn(label: Text('Evidencia', style: TextStyle(color: Colors.white))),
          ],
          rows: filas.map((f) {
            return DataRow(cells: [
              DataCell(Text(f['principio'] ?? '')),
              DataCell(Text(f['comportamiento'] ?? '')),
              DataCell(Text(f['nivel'] ?? '')),
              DataCell(Text(f['nombreAsociado'] ?? '')),
              DataCell(Text('${f['calificacion'] ?? ''}')),
              DataCell(Text((f['sistemasAsociados'] as List<String>).join(', '))),
              DataCell(Text(f['observacion'] ?? '')),
              DataCell(Text(f['evidencia'] ?? '')),
            ]);
          }).toList(),
        ),
      ),
    );
  }
}
