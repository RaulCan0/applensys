import 'package:flutter/material.dart';
import 'package:applensys/services/supabase_service.dart';
import 'package:applensys/models/calificacion.dart';

class TablasDimensionScreen extends StatelessWidget {
  const TablasDimensionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Resumen por Dimensión'),
          backgroundColor: Colors.indigo,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Dimensión 1'),
              Tab(text: 'Dimensión 2'),
              Tab(text: 'Dimensión 3'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _TablaDimensionUno(),
            _TablaDimensionDos(),
            _TablaDimensionTres(),
          ],
        ),
      ),
    );
  }
}

final supabaseService = SupabaseService();

class _TablaDimensionUno extends StatelessWidget {
  const _TablaDimensionUno();

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Contenido de Dimensión 1'));
  }
}

class _TablaDimensionDos extends StatelessWidget {
  const _TablaDimensionDos();

  @override
  Widget build(BuildContext context) {
    return _buildTablaFija('1', 5, [2, 3, 3, 3, 3]);
  }
}

class _TablaDimensionTres extends StatelessWidget {
  const _TablaDimensionTres();

  @override
  Widget build(BuildContext context) {
    return _buildTablaFija('2', 3, [2, 3, 3]);
  }
}

Widget _buildTablaFija(
  String dimension,
  int principios,
  List<int> comportamientosPorPrincipio,
) {
  return FutureBuilder<List<Calificacion>>(
    future: supabaseService.getAllCalificaciones(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final calificaciones = snapshot.data!;
      final Map<String, int> mapa = {
        for (var c in calificaciones) c.comportamiento: c.puntaje,
      };

      List<DataRow> filas = [];
      int comportamientoGlobal = 1;

      for (int p = 0; p < principios; p++) {
        final principioLabel = '$dimension-P${p + 1}';
        final totalComportamientos = comportamientosPorPrincipio[p];

        for (int c = 0; c < totalComportamientos; c++) {
          final comportamientoLabel = 'C$comportamientoGlobal';

          String claveEjecutivo =
              '$principioLabel-$comportamientoLabel-Ejecutivo';
          String claveGerente = '$principioLabel-$comportamientoLabel-Gerente';
          String claveMiembro = '$principioLabel-$comportamientoLabel-Miembro';

          filas.add(
            DataRow(
              cells: [
                DataCell(c == 0 ? Text(principioLabel) : const Text('')),
                DataCell(Text(comportamientoLabel)),
                DataCell(Text(mapa[claveEjecutivo]?.toString() ?? '-')),
                DataCell(Text(mapa[claveGerente]?.toString() ?? '-')),
                DataCell(Text(mapa[claveMiembro]?.toString() ?? '-')),
              ],
            ),
          );

          comportamientoGlobal++;
        }
      }

      return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        padding: const EdgeInsets.all(16),
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Principio')),
            DataColumn(label: Text('Comportamiento')),
            DataColumn(label: Text('Ejecutivo')),
            DataColumn(label: Text('Gerente')),
            DataColumn(label: Text('Miembro')),
          ],
          rows: filas,
        ),
      );
    },
  );
}
