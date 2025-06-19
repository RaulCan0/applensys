import 'package:flutter/material.dart';
import '../models/empresa.dart';
import '../models/evaluacion.dart';
import '../models/detalle_evaluacion.dart';
import '../services/shingo_result_service.dart';

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
    // Filtrar detalles de la empresa
    final detallesEmpresa = detalles.where((d) =>
      evaluaciones.any((e) => e.id == d.evaluacionId && e.empresaId == empresa.id)
    ).toList();

    // Función para calcular % ponderado obtenido
    double promedioPonderado(int nivel, List<String> comps) {
      final datos = detallesEmpresa
          .where((d) => d.nivel == nivel && comps.contains(d.comportamientoId));
      if (datos.isEmpty) return 0.0;
      final sumaCalif = datos.fold<double>(0, (sum, d) => sum + d.calificacion);
      final totalMax = datos.length * 5;
      return totalMax > 0 ? (sumaCalif / totalMax) * 100 : 0.0;
    }

    // Definir secciones con puntos posibles
    const sections = [
      {
        'label': 'Impulsores Culturales (250 pts)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'compsText': ['EJECUTIVOS 50%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 20%'],
        'puntos': ['125', '75', '50'],
      },
      {
        'label': 'Mejora Continua (350 pts)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'compsText': ['EJECUTIVOS 20%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 50%'],
        'puntos': ['70', '105', '175'],
      },
      {
        'label': 'Alineamiento Empresarial (200 pts)',
        'comps': ['EJECUTIVOS', 'GERENTES', 'MIEMBROS DE EQUIPO'],
        'compsText': ['EJECUTIVOS 55%', 'GERENTES 30%', 'MIEMBROS DE EQUIPO 15%'],
        'puntos': ['110', '60', '30'],
      },
    ];

    // Construir filas de la tabla principal
    final rows = <DataRow>[];
    for (var sec in sections) {
      final label = sec['label'] as String;
      final comps = sec['comps'] as List<String>;
      final puntos = (sec['puntos'] as List<String>).map(int.parse).toList();

      // Fila de sección: muestra label y nombres de componentes
      rows.add(DataRow(
        color: WidgetStateProperty.all(const Color(0xFF003056)),
        cells: [
          DataCell(Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          DataCell(Text(comps[0], style: const TextStyle(color: Colors.white))),
          DataCell(Text(comps[1], style: const TextStyle(color: Colors.white))),
          DataCell(Text(comps[2], style: const TextStyle(color: Colors.white))),
        ],
      ));
      // Puntos posibles
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos posibles', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[0].toString(), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[1].toString(), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text(puntos[2].toString(), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
      // % Obtenido
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('% Obtenido', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(1, comps).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(2, comps).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('${promedioPonderado(3, comps).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
      // Puntos obtenidos
      rows.add(DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          const DataCell(Text('Puntos obtenidos', style: TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(1, comps) / 100 * puntos[0]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(2, comps) / 100 * puntos[1]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text((promedioPonderado(3, comps) / 100 * puntos[2]).toStringAsFixed(0), style: const TextStyle(color: Color(0xFF003056)))),
        ],
      ));
    }

    // Etiquetas y valores para la tabla auxiliar
    const auxLabels = [
      'seguridad/medio ambiente/moral',
      'satisfacción del cliente',
      'calidad',
      'costo/productividad',
      'entregas',
    ];
    final shingoService = ShingoResultService();
    final auxRows = auxLabels.map((label) {
      final calif = shingoService.getCalificacion(label) ?? 0;
      return DataRow(
        color: WidgetStateProperty.all(Colors.grey.shade200),
        cells: [
          DataCell(Text(label, style: const TextStyle(color: Color(0xFF003056)))),
          DataCell(Text('$calif', style: const TextStyle(color: Color(0xFF003056)))),
          const DataCell(Text('Obtenido', style: TextStyle(color: Color(0xFF003056)))),
        ],
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        title: const Center(
          child: Text('Resumen Global', style: TextStyle(color: Colors.white)),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DataTable(
                // Ocultar completamente la fila de encabezado
                headingRowHeight: 0,
                showBottomBorder: false,
                columnSpacing: 36,
                border: TableBorder.all(color: const Color(0xFF003056)),
                columns: const [
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                  DataColumn(label: SizedBox.shrink()),
                ],
                rows: rows,
              ),
              const SizedBox(width: 24),
              DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFF003056)),
                headingTextStyle: const TextStyle(color: Colors.white),
                columnSpacing: 24,
                border: TableBorder.all(color: const Color(0xFF003056)),
                columns: const [
                  DataColumn(label: Text('Resultado', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Valor', style: TextStyle(color: Colors.white))),
                  DataColumn(label: Text('Obtenido', style: TextStyle(color: Colors.white))),
                ],
                rows: auxRows,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
