import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ReporteComportamiento {
  final String comportamiento;
  final String definicion;
  final String nivel;
  final int calificacion;          // valor redondeado
  final List<String> sistemasAsociados;
  final String resultado;          // texto C1..C5
  final String benchmark;
  final String observacion;        // hallazgo específico
  final Map<String, double> grafico;

  ReporteComportamiento({
    required this.comportamiento,
    required this.definicion,
    required this.nivel,
    required this.calificacion,
    required this.sistemasAsociados,
    required this.resultado,
    required this.benchmark,
    required this.observacion,
    required this.grafico,
  });
}

class ReporteUtils {
  static const List<String> _nivelesFijos = [
    'Ejecutivo',
    'Gerente',
    'Miembro de equipo',
  ];

  static Future<List<ReporteComportamiento>> generarReporteDesdeTablaDatos(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final List<ReporteComportamiento> reporte = [];
    final mapaGrafico = <String, Map<String, double>>{};

    for (var dato in tablaDatos) {
      final comp = dato['comportamiento'].toString().trim();
      final nivel = dato['nivel'].toString().trim();
      final dim = dato['dimension'].toString();
      final raw = double.tryParse(dato['calificacion'].toString()) ?? 0.0;
      final redondeo = (raw % 1) >= 0.5 ? raw.ceil() : raw.floor();
      final sistemas = List<String>.from(dato['sistemas_asociados'] ?? []).toSet().toList();
      final obs = dato['observacion']?.toString().trim() ?? '';

      final fuente = dim == '1' ? t1 : (dim == '2' ? t2 : t3);
      final bench = fuente.firstWhere(
        (b) => b['BENCHMARK DE COMPORTAMIENTOS']
                .toString().trim().startsWith(comp) &&
               b['NIVEL']
                .toString().toLowerCase().contains(nivel.toLowerCase().split(' ')[0]),
        orElse: () => <String, dynamic>{},
      );
      final definicion = bench['BENCHMARK DE COMPORTAMIENTOS'] ?? '';
      final bm = bench['BENCHMARK POR NIVEL'] ?? '';

      String interpret = '';
      switch (redondeo) {
        case 1:
          interpret = bench['C1'] ?? '';
          break;
        case 2:
          interpret = bench['C2'] ?? '';
          break;
        case 3:
          interpret = bench['C3'] ?? '';
          break;
        case 4:
          interpret = bench['C4'] ?? '';
          break;
        case 5:
          interpret = bench['C5'] ?? '';
          break;
      }

      mapaGrafico.putIfAbsent(comp, () => {});
      mapaGrafico[comp]![nivel] = raw;

      reporte.add(ReporteComportamiento(
        comportamiento: comp,
        definicion: definicion,
        nivel: nivel,
        calificacion: redondeo,
        sistemasAsociados: sistemas,
        resultado: interpret,
        benchmark: bm,
        observacion: obs,
        grafico: {},
      ));
    }

    for (var r in reporte) {
      r.grafico.addAll({
        'Ejecutivo': mapaGrafico[r.comportamiento]?['Ejecutivo'] ?? 0,
        'Gerente': mapaGrafico[r.comportamiento]?['Gerente'] ?? 0,
        'Miembro de equipo': mapaGrafico[r.comportamiento]?['Miembro de equipo'] ?? 0,
      });
    }

    return reporte;
  }

  static Future<String> exportReporteWordUnificado(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporteDesdeTablaDatos(tablaDatos, t1, t2, t3);
    final buffer = StringBuffer();
    buffer.writeln('<html><body>');

    // Generar secciones por comportamiento
    final comps = reporte.map((r) => r.comportamiento).toSet();
    for (var comp in comps) {
      final filas = reporte.where((r) => r.comportamiento == comp).toList();
      final defin = filas.first.definicion;
      buffer.writeln('<h2>$comp</h2>');
      buffer.writeln('<p>$defin</p>');
      buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
      buffer.writeln(
          '<tr><th>Nivel</th><th>Resultado</th><th>Sistemas Asociados</th><th>Hallazgos Específicos</th><th>Interpretación</th><th>Benchmark</th><th>Evidencia</th></tr>');

      for (var nivel in _nivelesFijos) {
        final rowData = filas.firstWhere(
          (r) => r.nivel.toLowerCase().contains(nivel.toLowerCase().split(' ')[0]),
          orElse: () => filas.first,
        );
        final sis = rowData.sistemasAsociados.join(', ');
        buffer.writeln('<tr>');
        buffer.writeln('<td>$nivel</td>');
        buffer.writeln('<td>${rowData.calificacion}</td>');
        buffer.writeln('<td>$sis</td>');
        buffer.writeln('<td>${rowData.observacion}</td>');
        buffer.writeln('<td>${rowData.resultado}</td>');
        buffer.writeln('<td>${rowData.benchmark}</td>');
        // Espacio para evidencia: se inserta la ruta de imagen
        buffer.writeln('<td><img src="${rowData.grafico[nivel]?.toString() ?? ''}" width="100" height="100"/></td>');
        buffer.writeln('</tr>');
      }

      buffer.writeln('</table><br/>');
    }

    // Extras del reporte: 28 tablitas individuales con evidencia
    buffer.writeln('<h2>Extras del Reporte</h2>');
    final comportamientos = [
      'Soporte','Reconocer','Comunidad','Liderazgo de Servidor','Valorar','Empoderamiento',
      'Mentalidad','Estructura','Reflexionar','Análisis','Colaborar','Comprender','Diseño',
      'Atribución','A prueba de error','Propiedad','Conectar','Ininterrumpido','Demanda',
      'Eliminar','Optimizar','Impacto','Alinear','Aclarar','Comunicar','Relación','Medida','Valor',
    ];
    for (var comp in comportamientos) {
      buffer.writeln('<h3>$comp</h3>');
      buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
      buffer.writeln('<tr><th>Nivel</th><th>Evidencia</th></tr>');
      for (var nivel in _nivelesFijos) {
        buffer.writeln('<tr><td>$nivel</td><td><img src="" width="100" height="100"/></td></tr>');
      }
      buffer.writeln('</table><br/>');
    }

    buffer.writeln('</body></html>');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_unificado.doc');
    await file.writeAsString(buffer.toString(), encoding: Utf8Codec());
    return file.path;
  }
}
