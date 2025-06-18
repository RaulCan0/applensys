import 'package:flutter/material.dart';
import '../models/empresa.dart';
import '../models/evaluacion.dart';
import '../models/detalle_evaluacion.dart';

class TablaScoreGlobal extends StatelessWidget {
  final Empresa empresa;
  final List<DetalleEvaluacion> detalles;
  final List<Evaluacion> evaluaciones;

  const TablaScoreGlobal({
    super.key,
    required this.empresa,
    required this.detalles,
    required this.evaluaciones,
  });

  @override
  Widget build(BuildContext context) {
    // Filtramos solo los detalles que pertenezcan a esta empresa
    final detallesEmpresa = detalles.where((d) =>
      evaluaciones.any((e) => e.id == d.evaluacionId && e.empresaId == empresa.id)
    ).toList();

    double promedioPonderado(int nivel, List<String> comportamientos) {
      final datos = detallesEmpresa.where((d) =>
        d.nivel == nivel && comportamientos.contains(d.comportamientoId)
      );
      if (datos.isEmpty) return 0.0;
      final suma = datos.fold<int>(0, (sum, d) => sum + d.calificacion);
      final total = datos.length * 5;
      return (suma / total) * 100;
    }

    // Asegúrate de que cada sección tenga tantas claves de 'comps' como de 'pesos'
    const sections = [
      {
        'label': 'Impulsores Culturales (250 puntos)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'pesos': ['50%', '30%', '20%'],
         'puntos': ['125', '75', '50'],
      },
      {
        'label': 'Mejora Continua (350 puntos)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'pesos': ['20%', '30%', '50%'],
        'puntos': ['70', '105', '175'],
      },
      {
        'label': 'Alineamiento Empresarial (200 puntos)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'pesos': ['55%', '30%', '15%'],
        'puntos': ['110', '60', '30'],
      },
    ];

    final filas = <DataRow>[];
    for (var sec in sections) {
      final label = sec['label'] as String;
      final comps = sec['comps'] as List<String>;
      final pesos = sec['pesos'] as List<String>;

      // Fila de encabezado de sección
      filas.add(DataRow(cells: [
        DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
        const DataCell(Text("Ejecutivos")),
        const DataCell(Text("Gerentes")),
        const DataCell(Text("Miembros")),
      ]));

      // Fila de pesos posibles
      filas.add(DataRow(cells: [
        const DataCell(Text('% Ponderado posible')),
        DataCell(Text(pesos[0])),
        DataCell(Text(pesos[1])),
        DataCell(Text(pesos[2])),
      ]));

      // Fila de resultados obtenidos
      filas.add(DataRow(cells: [
        const DataCell(Text('% Ponderado obtenido')),
        DataCell(Text('${promedioPonderado(1, comps).toStringAsFixed(1)}%')),
        DataCell(Text('${promedioPonderado(2, comps).toStringAsFixed(1)}%')),
        DataCell(Text('${promedioPonderado(3, comps).toStringAsFixed(1)}%')),
      ]));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(Colors.grey[800]),
        headingTextStyle: const TextStyle(color: Colors.white),
        columns: const [
          DataColumn(label: Text('SCORE DE LA EVALUACIÓN')),
          DataColumn(label: Text('Ejecutivos')),
          DataColumn(label: Text('Gerentes')),
          DataColumn(label: Text('Miembros del Equipo')),
        ],
        rows: filas,
      ),
    );
  }
}
