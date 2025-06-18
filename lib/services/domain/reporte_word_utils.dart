
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
    final outputFile = File('${outputDir.path}/prereporte_lensysapp.docx');
    if (generated != null) {
      await outputFile.writeAsBytes(generated);
    }
    return outputFile;
  }
}
