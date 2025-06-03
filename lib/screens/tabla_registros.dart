import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/widgets/drawer_lensys.dart';

class TablasRegistrosScreen extends StatefulWidget {
  final String evaluacionId;
  final String empresaId;
  final String asociadoId;
  final String dimensionId;

  const TablasRegistrosScreen({
    super.key,
    required this.evaluacionId,
    required this.empresaId,
    required this.asociadoId,
    required this.dimensionId,
  });

  @override
  State<TablasRegistrosScreen> createState() => _TablasRegistrosScreenState();
}

class _TablasRegistrosScreenState extends State<TablasRegistrosScreen> {
  final Map<String, String> _dimMap = {
    'Dimensión 1': '1',
    'Dimensión 2': '2',
    'Dimensión 3': '3',
  };

  late List<String> dimensiones;

  @override
  void initState() {
    super.initState();
    dimensiones = _dimMap.keys.toList();
  }

  Future<List<Map<String, dynamic>>> _fetchRegistros(String dimNombre) async {
    final dimId = _dimMap[dimNombre];
    // Especifica las columnas que existen en tu tabla 'calificaciones'
    const String selectColumns = 'id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url'; // Asegúrate que estas columnas existan

    final response = await Supabase.instance.client
        .from('calificaciones')
        .select(selectColumns) // Selecciona explícitamente las columnas
        // .eq('evaluacion_id', widget.evaluacionId) // Eliminado o ajusta si 'evaluacion_id' existe con otro nombre o si el filtro es diferente
        .eq('id_empresa', widget.empresaId)
        .eq('id_asociado', widget.asociadoId)
        .eq('id_dimension', dimId!);

    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

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
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchRegistros(dim),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No hay registros'));
                } else {
                  return _buildDataTable(snapshot.data!);
                }
              },
            );
          }).toList(),
        ),
        floatingActionButton: Builder(
          builder: (BuildContext fabContext) {
            return FloatingActionButton(
              onPressed: () {
                final tabController = DefaultTabController.of(fabContext);
                final currentIndex = tabController.index;
                final currentDimensionKey = dimensiones[currentIndex];

                ScaffoldMessenger.of(fabContext).showSnackBar(
                  SnackBar(content: Text('Añadir nuevo registro a: $currentDimensionKey (acción pendiente)')),
                );
              },
              backgroundColor: const Color(0xFF003056),
              tooltip: 'Añadir nuevo registro',
              child: const Icon(Icons.add, color: Colors.white),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDataTable(List<Map<String, dynamic>> filas) {
    return Semantics(
      label: 'Tabla de registros de evaluación',
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          child: DataTable(
            columnSpacing: 16,
            headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
            border: TableBorder.all(color: const Color(0xFF003056)),
            columns: const [
              DataColumn(label: Text('Comportamiento', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Puntaje', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Fecha Evaluación', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Observaciones', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Sistemas', style: TextStyle(color: Colors.white))),
              DataColumn(label: Text('Evidencia URL', style: TextStyle(color: Colors.white))),
            ],
            rows: filas.map((f) {
              return DataRow(cells: [
                DataCell(Text(f['comportamiento'] ?? '')),
                DataCell(Text('${f['puntaje'] ?? ''}')),
                DataCell(Text(f['fecha_evaluacion']?.toString().split('T').first ?? '')),
                DataCell(Text(f['observaciones'] ?? '')),
                DataCell(Text(f['sistemas'] ?? '')),
                DataCell(Text(f['evidencia_url'] ?? '')),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }
}
