import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ReporteComportamiento {
  final String comportamiento;
  final String definicion;
  final String nivel;
  final int calificacion;
  final List<String> sistemasAsociados;
  final String resultado;
  final String benchmark;
  final Map<String, double> grafico;

  ReporteComportamiento({
    required this.comportamiento,
    required this.definicion,
    required this.nivel,
    required this.calificacion,
    required this.sistemasAsociados,
    required this.resultado,
    required this.benchmark,
    required this.grafico,
  });

  Map<String, dynamic> toJson() => {
        'comportamiento': comportamiento,
        'definicion': definicion,
        'nivel': nivel,
        'calificacion': calificacion,
        'sistemas_asociados': sistemasAsociados,
        'resultado': resultado,
        'benchmark': benchmark,
        'grafico': grafico,
      };
}

class ReporteUtils {
  static Future<List<ReporteComportamiento>> generarReporteDesdeTablaDatos(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    List<ReporteComportamiento> reporte = [];
    Map<String, Map<String, double>> mapaGrafico = {};

    for (var dato in tablaDatos) {
      final String comportamiento = dato['comportamiento'];
      final String nivel = dato['nivel'];
      final String dimension = dato['dimension'].toString();
      final double calificacion = double.tryParse(dato['calificacion'].toString()) ?? 0.0;
      final int redondeada = (calificacion % 1) >= 0.5 ? calificacion.ceil() : calificacion.floor();
      final List<String> sistemas = List<String>.from(dato['sistemas_asociados'] ?? []);

      List<Map<String, dynamic>> fuente = [];
      if (dimension == "1") {
        fuente = t1;
      } else if (dimension == "2") {
        fuente = t2;
      } else if (dimension == "3") {
        fuente = t3;
      }

      final benchmarkData = fuente.firstWhere(
        (b) => b['BENCHMARK DE COMPORTAMIENTOS'].toString().trim() == comportamiento.trim() &&
               b['NIVEL'].toString().toLowerCase().contains(nivel.toLowerCase().split(' ')[0]),
        orElse: () => {},
      );

      final String definicion = benchmarkData['BENCHMARK DE COMPORTAMIENTOS'] ?? '';
      final String benchmark = benchmarkData['BENCHMARK POR NIVEL'] ?? '';

      String resultado = '';
      switch (redondeada) {
        case 1:
          resultado = benchmarkData['C1'] ?? '';
          break;
        case 2:
          resultado = benchmarkData['C2'] ?? '';
          break;
        case 3:
          resultado = benchmarkData['C3'] ?? '';
          break;
        case 4:
          resultado = benchmarkData['C4'] ?? '';
          break;
        case 5:
          resultado = benchmarkData['C5'] ?? '';
          break;
      }

      mapaGrafico.putIfAbsent(comportamiento, () => {});
      mapaGrafico[comportamiento]![nivel] = calificacion;

      reporte.add(ReporteComportamiento(
        comportamiento: comportamiento,
        definicion: definicion,
        nivel: nivel,
        calificacion: redondeada,
        sistemasAsociados: sistemas.toSet().toList(),
        resultado: resultado,
        benchmark: benchmark,
        grafico: {},
      ));
    }

    for (var r in reporte) {
      r.grafico.addAll({
        'Ejecutivos': mapaGrafico[r.comportamiento]?['Ejecutivos'] ?? 0,
        'Gerentes': mapaGrafico[r.comportamiento]?['Gerentes'] ?? 0,
        'Equipo': mapaGrafico[r.comportamiento]?['Equipo'] ??
                  mapaGrafico[r.comportamiento]?['Miembro'] ?? 0,
      });
    }

    return reporte;
  }

  static Future<String> exportReporteWord(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporteDesdeTablaDatos(tablaDatos, t1, t2, t3);
    final buffer = StringBuffer();
    buffer.writeln('<html><body><h1>Reporte de Comportamientos</h1>');
    buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
    buffer.writeln('<tr><th>Comportamiento</th><th>Definición</th><th>Nivel</th><th>Calificación</th><th>Resultado</th><th>Benchmark</th><th>Sistemas Asociados</th></tr>');
    for (var r in reporte) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>${r.comportamiento}</td>');
      buffer.writeln('<td>${r.definicion}</td>');
      buffer.writeln('<td>${r.nivel}</td>');
      buffer.writeln('<td>${r.calificacion}</td>');
      buffer.writeln('<td>${r.resultado}</td>');
      buffer.writeln('<td>${r.benchmark}</td>');
      buffer.writeln('<td>${r.sistemasAsociados.join(", ")}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table>');
    
    // Tabla con las calificaciones detalladas de asociados, dimensión, principio, comportamiento, observaciones y sistemas asociados
    buffer.writeln('<h2>Detalles de Evaluación</h2>');
    buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
    buffer.writeln('<tr><th>Asociado</th><th>Dimensión</th><th>Principio</th><th>Comportamiento</th><th>Observaciones</th><th>Sistemas Asociados</th></tr>');
    for (var dato in tablaDatos) {
      buffer.writeln('<tr>');
      buffer.writeln('<td>${dato['asociado_nombre']}</td>');
      buffer.writeln('<td>${dato['dimension']}</td>');
      buffer.writeln('<td>${dato['principio']}</td>');
      buffer.writeln('<td>${dato['comportamiento']}</td>');
      buffer.writeln('<td>${dato['observacion']}</td>');
      buffer.writeln('<td>${dato['sistemas_asociados'].join(", ")}</td>');
      buffer.writeln('</tr>');
    }
    buffer.writeln('</table></body></html>');

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/reporte_completo.doc');
    await file.writeAsString(buffer.toString(), encoding: Utf8Codec());
    return file.path;
  }
}
