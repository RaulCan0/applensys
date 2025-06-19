/*import 'dart:io';
import 'dart:typed_data';
import 'package:docx_template/docx_template.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class ReporteWordUtils {
  static Future<File> generarWord({
    required String empresa,
    required String ubicacion,
    required Uint8List portadaBytes,
    required List<Uint8List> graficosDashboard,
    required List<Map<String, dynamic>> tablaDatos, // datos en bruto
    required List<Map<String, dynamic>> t1,
    required List<Map<String, dynamic>> t2,
    required List<Map<String, dynamic>> t3,
    required Map<String, Uint8List> graficosPorComportamiento, required List<Map<String, dynamic>> datosComportamientos, required List comportamientos, // titulo -> imagen
  }) async {
    final bytes = await rootBundle.load('assets/plantilla_prereporte.docx');
    final doc = await DocxTemplate.fromBytes(bytes.buffer.asUint8List());

    final content = Content()
      ..add(TextContent("empresa", empresa))
      ..add(TextContent("ubicacion", ubicacion))
      ..add(ImageContent("portada", portadaBytes))
      ..add(ListContent("graficos", graficosDashboard.map((g) {
        return Content()..add(ImageContent("grafico", g));
      }).toList()));

    // Agrupar por comportamiento
    final comportamientoGrupo = <String, List<Map<String, dynamic>>>{};
    for (var row in tablaDatos) {
      final c = row['comportamiento']?.toString().trim() ?? '';
      if (c.isEmpty) continue;
      comportamientoGrupo.putIfAbsent(c, () => []).add(row);
    }

    final List<Content> comportamientosContent = [];

    for (final comportamiento in comportamientoGrupo.keys) {
      final filas = comportamientoGrupo[comportamiento]!;
      final fila = filas.first;
      final dim = fila['dimension'].toString();
      final fuente = dim == '1' ? t1 : (dim == '2' ? t2 : t3);

      final benchmarkEntry = fuente.firstWhere(
        (e) =>
            e['BENCHMARK DE COMPORTAMIENTOS']
                .toString()
                .trim()
                .startsWith(comportamiento) &&
            e['NIVEL']
                .toString()
                .toLowerCase()
                .contains('ejecutivo'),
        orElse: () => {},
      );

      final definicion = benchmarkEntry['BENCHMARK DE COMPORTAMIENTOS'] ?? '';

      final nivelKeys = ['Ejecutivo', 'Gerente', 'Miembro de equipo'];

      final nivelesContent = nivelKeys.map((nivel) {
        final row = filas.firstWhere(
          (r) => r['nivel'].toString().toLowerCase().contains(nivel.toLowerCase().split(' ')[0]),
          orElse: () => {},
        );
        final cal = double.tryParse(row['calificacion']?.toString() ?? '0') ?? 0;
        final redondeo = (cal % 1) >= 0.5 ? cal.ceil() : cal.floor();

        final fuenteNivel = fuente.firstWhere(
          (e) =>
              e['BENCHMARK DE COMPORTAMIENTOS']
                  .toString()
                  .trim()
                  .startsWith(comportamiento) &&
              e['NIVEL']
                  .toString()
                  .toLowerCase()
                  .contains(nivel.toLowerCase().split(' ')[0]),
          orElse: () => {},
        );

        final interpretacion = fuenteNivel['C$redondeo'] ?? '';
        final benchmark = fuenteNivel['BENCHMARK POR NIVEL'] ?? '';
        final hallazgos = row['observacion'] ?? '';
        final sistemas = (row['sistemas_asociados'] as List?)?.join(', ') ?? '';

        return Content()
          ..add(TextContent("nivel", nivel))
          ..add(TextContent("resultado", cal.toStringAsFixed(2)))
          ..add(TextContent("sistemas", sistemas))
          ..add(TextContent("hallazgos", hallazgos))
          ..add(TextContent("interpretacion", interpretacion))
          ..add(TextContent("benchmark", benchmark));
      }).toList();

      final grafico = graficosPorComportamiento[comportamiento] ?? Uint8List(0);

      comportamientosContent.add(Content()
        ..add(TextContent("titulo", comportamiento))
        ..add(TextContent("definicion", definicion))
        ..add(ListContent("niveles", nivelesContent))
        ..add(ImageContent("grafico_comportamiento", grafico)));
    }

    content.add(ListContent("comportamientos", comportamientosContent));

    final generated = await doc.generate(content);
    if (generated == null) {
      throw Exception("No se pudo generar el documento Word.");
    }

    final outputDir = await getTemporaryDirectory();
    final outputFile = File('${outputDir.path}/prereporte_lensysapp.docx');
    await outputFile.writeAsBytes(generated);
    return outputFile;
  }
}*/


import 'dart:io';
import 'dart:typed_data';
import 'package:docx_template/docx_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;

class ReporteWordUtils {
  /// Genera el archivo Word (.docx) real con portada, gráficos y comportamiento
  static Future<File> generarWord({
    required String empresa,
    required String ubicacion,
    required Uint8List portadaBytes,
    required List<Uint8List> graficosDashboard,
    required List<Map<String, dynamic>> datosComportamientos,
  }) async {
    final bytes = await rootBundle.load('assets/plantilla_prereporte.docx');
    final doc = await DocxTemplate.fromBytes(bytes.buffer.asUint8List());
    final content = Content();

    content
      ..add(TextContent("empresa", empresa))
      ..add(TextContent("ubicacion", ubicacion))
      ..add(ImageContent("portada", portadaBytes))
      ..add(ListContent("graficos", List.generate(graficosDashboard.length, (i) {
        return Content()
          ..add(ImageContent("grafico", graficosDashboard[i]));
      })))
      ..add(ListContent("comportamientos", datosComportamientos.map((data) {
        return Content()
          ..add(TextContent("titulo", data['titulo']))
          ..add(TextContent("definicion", data['definicion']))
          ..add(ListContent("niveles", ["ejecutivo", "gerente", "m.equipo"].map((nivel) {
            final entry = data[nivel];
            return Content()
              ..add(TextContent("nivel", nivel.toUpperCase()))
              ..add(TextContent("resultado", entry['resultado'].toStringAsFixed(2)))
              ..add(TextContent("sistemas", entry['sistemas'].join(', ')))
              ..add(TextContent("hallazgos", entry['hallazgos']))
              ..add(TextContent("interpretacion", entry['interpretacion']))
              ..add(TextContent("benchmark", entry['benchmark']));
          }).toList()))
          ..add(ImageContent("grafico_comportamiento", data['grafico']));
      }).toList()));

    final generated = await doc.generate(content);
    final outputDir = await getTemporaryDirectory();
    final outputFile = File('${outputDir.path}/prereporte.docx');
    if (generated != null) {
      await outputFile.writeAsBytes(generated);
    }
    return outputFile;
  }
}
