import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart'; // Importación para el paquete excel

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

  /// Genera lista de ReporteComportamiento a partir de tablas de datos y benchmarks.
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

      // seleccionar fuente de benchmark
      final fuente = dim == '1' ? t1 : (dim == '2' ? t2 : t3);
      final bench = fuente.firstWhere(
        (b) => b['BENCHMARK DE COMPORTAMIENTOS']
                .toString()
                .trim()
                .startsWith(comp) &&
               b['NIVEL']
                .toString()
                .toLowerCase()
                .contains(nivel.toLowerCase().split(' ')[0]),
        orElse: () => {},
      );
      final definicion = bench['BENCHMARK DE COMPORTAMIENTOS'] ?? '';
      final bm = bench['BENCHMARK POR NIVEL'] ?? '';

      // texto de interpretación según redondeo C1..C5
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

    // asignar datos de gráfico (no modificado)
    for (var r in reporte) {
      r.grafico.addAll({
        'Ejecutivo': mapaGrafico[r.comportamiento]?['Ejecutivo'] ?? 0,
        'Gerente': mapaGrafico[r.comportamiento]?['Gerente'] ?? 0,
        'Miembro de equipo': mapaGrafico[r.comportamiento]?['Miembro'] ??
                                mapaGrafico[r.comportamiento]?['Equipo'] ?? 0,
      });
    }

    return reporte;
  }

  /// Exporta un documento Word (.doc) basado en HTML.
  /// Solo coloca COMPORTAMIENTO y DEFINICIÓN arriba de cada tabla.
  /// La tabla fija 3 filas: Ejecutivo, Gerente, Miembro de equipo.
  /// Columnas: Nivel | Resultado (calificación) | Sistemas Asociados |
  /// Hallazgos Específicos | Interpretación del Comportamiento |
  /// Benchmark | Gráfico
  static Future<String> exportReporteWordUnificado(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporteDesdeTablaDatos(tablaDatos, t1, t2, t3);
    final buffer = StringBuffer();
    buffer.writeln('<html><body>');

    final comps = reporte.map((r) => r.comportamiento).toSet();
    for (var comp in comps) {
      final filas = reporte.where((r) => r.comportamiento == comp).toList();
      if (filas.isEmpty) continue; // Si no hay filas para este comportamiento, saltar.

      final defin = filas.first.definicion; // Asumimos que la definición es la misma para todas las filas de un comportamiento.
      buffer.writeln('<h2>$comp</h2>');
      buffer.writeln('<p>$defin</p>');
      buffer.writeln('<table border="1" cellspacing="0" cellpadding="4">');
      buffer.writeln('<tr>'
          '<th>Nivel</th>'
          '<th>Resultado</th>'
          '<th>Sistemas Asociados</th>'
          '<th>Hallazgos Específicos</th>'
          '<th>Interpretación del Comportamiento</th>'
          '<th>Benchmark</th>'
          '<th>Gráfico</th>'
          '</tr>');

      for (var nivelFijo in _nivelesFijos) {
        final rowData = filas.firstWhere(
          (r) => r.nivel.toLowerCase().contains(
                    nivelFijo.toLowerCase().split(' ')[0] // Compara la primera palabra del nivel
                  ),
          // Si no se encuentra, crea un ReporteComportamiento vacío para esa fila de la tabla.
          orElse: () => ReporteComportamiento(
            comportamiento: comp,
            definicion: defin, // Reutiliza la definición del comportamiento actual
            nivel: nivelFijo,
            calificacion: 0,
            sistemasAsociados: [],
            resultado: 'N/A',
            benchmark: 'N/A',
            observacion: 'N/A',
            grafico: {},
          ),
        );
        final sis = rowData.sistemasAsociados.join(', ');
        final hall = rowData.observacion;
        final interp = rowData.resultado;
        final bm = rowData.benchmark;
        // Aquí necesitarías una forma de generar y enlazar la imagen del gráfico.
        // Por ahora, se deja como una celda vacía o con un placeholder.
        final graficoHtml = rowData.grafico.isNotEmpty 
            ? 'Datos disponibles' // Placeholder, idealmente aquí iría una imagen o un mini-gráfico HTML/SVG
            : 'N/A';

        buffer.writeln('<tr>');
        buffer.writeln('<td>${rowData.nivel}</td>'); // Usar rowData.nivel que puede ser el nivelFijo o el nivel original
        buffer.writeln('<td>${rowData.calificacion}</td>');
        buffer.writeln('<td>$sis</td>');
        buffer.writeln('<td>$hall</td>');
        buffer.writeln('<td>$interp</td>');
        buffer.writeln('<td>$bm</td>');
        buffer.writeln('<td>$graficoHtml</td>'); // Celda para el gráfico
        buffer.writeln('</tr>');
      }
      buffer.writeln('</table>');
    }

    buffer.writeln('</body></html>');
    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/reporte_unificado.doc';
    final file = File(filePath);
    await file.writeAsString(buffer.toString(), encoding: Utf8Codec());
    return filePath;
  }

  /// Exporta un reporte en formato CSV.
  static Future<String> exportReporteExcelUnificado(
    List<Map<String, dynamic>> tablaDatos,
    List<Map<String, dynamic>> t1,
    List<Map<String, dynamic>> t2,
    List<Map<String, dynamic>> t3,
  ) async {
    final reporte = await generarReporteDesdeTablaDatos(tablaDatos, t1, t2, t3);
    
    var excel = Excel.createExcel(); 
    Sheet sheetObject = excel['ReporteUnificado']; 

    // Encabezados
    List<CellValue> headers = [
      TextCellValue('Comportamiento'), TextCellValue('Definicion'), TextCellValue('Nivel'), TextCellValue('Resultado (Calificacion)'),
      TextCellValue('Sistemas Asociados'), TextCellValue('Hallazgos Especificos'), TextCellValue('Interpretacion del Comportamiento'),
      TextCellValue('Benchmark'), TextCellValue('Grafico Ejecutivo'), TextCellValue('Grafico Gerente'), TextCellValue('Grafico Miembro de equipo')
    ];
    sheetObject.appendRow(headers);

    final comps = reporte.map((r) => r.comportamiento).toSet();
    for (var comp in comps) {
      final filasDelComportamiento = reporte.where((r) => r.comportamiento == comp).toList();
      if (filasDelComportamiento.isEmpty) continue;
      
      final definicionComportamiento = filasDelComportamiento.first.definicion;

      for (var nivelFijo in _nivelesFijos) {
        final rowData = filasDelComportamiento.firstWhere(
          (r) => r.nivel.toLowerCase().contains(nivelFijo.toLowerCase().split(' ')[0]),
         
        );

        final sistemas = rowData.sistemasAsociados.join('; ');
        
        List<CellValue?> rowValues = [
          TextCellValue(rowData.comportamiento),
          TextCellValue(rowData.definicion),
          TextCellValue(rowData.nivel),
          DoubleCellValue(rowData.calificacion.toDouble()), // Corregido: Usar DoubleCellValue
          TextCellValue(sistemas),
          TextCellValue(rowData.observacion),
          TextCellValue(rowData.resultado),
          TextCellValue(rowData.benchmark),
          DoubleCellValue(rowData.grafico['Ejecutivo'] ?? 0.0), // Corregido: Usar DoubleCellValue
          DoubleCellValue(rowData.grafico['Gerente'] ?? 0.0), // Corregido: Usar DoubleCellValue
          DoubleCellValue(rowData.grafico['Miembro de equipo'] ?? 0.0) // Corregido: Usar DoubleCellValue
        ];
        sheetObject.appendRow(rowValues);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final filePath = '${dir.path}/reporte_unificado.xlsx';
    
    var fileBytes = excel.save();
    if (fileBytes != null) {
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsBytesSync(fileBytes);
      return filePath;
    } else {
      throw Exception("Error al guardar el archivo Excel.");
    }
  }
}
