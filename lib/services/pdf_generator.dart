import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// Servicio para generar el reporte completo en PDF
typedef JsonMap = Map<String, dynamic>;
class PdfReportGenerator {
  /// Muestra diálogo para pedir organización, localización y recibe promedios de comportamientos,
  /// luego genera el PDF
  static Future<Uint8List?> promptAndGenerate(
    BuildContext context,
    List<JsonMap> dimensionesRaw,
    Map<String, List<double>> comportPromedios,
  ) async {
    final orgCtrl = TextEditingController();
    final locCtrl = TextEditingController();
    String? organizacion;
    String? localizacion;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Generar Reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: orgCtrl,
              decoration: const InputDecoration(labelText: 'Organización'),
            ),
            TextField(
              controller: locCtrl,
              decoration: const InputDecoration(labelText: 'Localización'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              organizacion = orgCtrl.text.trim();
              localizacion = locCtrl.text.trim();
              Navigator.of(context).pop();
            },
            child: const Text('Generar'),
          ),
        ],
      ),
    );

    if (organizacion == null || localizacion == null) return null;
    return await _generateOperationalReport(
      organizacion: organizacion!,
      localizacion: localizacion!,
      dimensionesRaw: dimensionesRaw,
      comportPromedios: comportPromedios,
    );
  }

  static Future<Uint8List> _generateOperationalReport({
    required String organizacion,
    required String localizacion,
    required List<JsonMap> dimensionesRaw,
    required Map<String, List<double>> comportPromedios,
  }) async {
    // 1. Cargar plantillas t1, t2 y t3
    final t1 = jsonDecode(
      await rootBundle.loadString('assets/t1.json'),
    ) as List<dynamic>;
    final t2 = jsonDecode(
      await rootBundle.loadString('assets/t2.json'),
    ) as List<dynamic>;
    final t3 = jsonDecode(
      await rootBundle.loadString('assets/t3.json'),
    ) as List<dynamic>;

    // 2. Cargar skeleton report.json
    final reportJson = jsonDecode(
      await rootBundle.loadString('assets/report.json'),
    ) as JsonMap;

    // 3. Inyectar datos dinámicos en reportJson usando promedios pasados
    for (final entry in reportJson.entries) {
      final compKey = entry.key;
      final datos = entry.value as JsonMap;
      final niveles = (datos['niveles'] as List).cast<JsonMap>();

      // Obtener promedios pre-calculados si existen
      final avgList = comportPromedios[compKey] ?? [0.0, 0.0, 0.0];
      final ejecAvg = avgList[0];
      final gertAvg = avgList[1];
      final miemAvg = avgList[2];

      // Buscar benchEntry en plantillas
      // Para ello necesitamos primer rawRow que coincida
      final rawMirror = dimensionesRaw.firstWhere(
        (r) => (r['comportamiento'] as String?)?.toLowerCase() == compKey.toLowerCase(),
        orElse: () => {},
      );
      final dim = rawMirror['dimension_id']?.toString() ?? '';
      final pri = rawMirror['principio']?.toString() ?? '';
      final benchList = dim == '1' ? t1 : dim == '2' ? t2 : t3;
      final benchEntry = benchList.cast<JsonMap>().firstWhere(
        (b) => b['PRINCIPIO'] == pri && b['COMPORTAMIENTO'] == compKey,
        orElse: () => {},
      );

      // Inyectar por nivel
      for (final nivelEntry in niveles) {
        final label = (nivelEntry['nivel'] as String?)?.toLowerCase() ?? '';
        final avg = label.contains('ejecutivo')
            ? ejecAvg
            : label.contains('gerente')
                ? gertAvg
                : miemAvg;
        nivelEntry['resultado'] = avg.toStringAsFixed(2);

        // Interpretación C1–C5 usando redondeo
        final rounded = (avg + 0.5).floor().clamp(1, 5);
        nivelEntry['interpretacion_comportamiento'] = benchEntry['C\$rounded'] ?? '';
        nivelEntry['benchmark'] = benchEntry['BENCHMARK POR NIVEL'] ?? '';

        // Sistemas y hallazgos desde rawRows
        final rowsForLevel = dimensionesRaw.where((r) =>
          (r['comportamiento'] as String?)?.toLowerCase() == compKey.toLowerCase() &&
          (r['cargo_raw'] as String?)?.toLowerCase().contains(label) == true
        );
        nivelEntry['sistemas_asociados'] = rowsForLevel
            .map((r) => r['sistemas_asociados']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ');
        nivelEntry['hallazgos_especificos'] = rowsForLevel
            .map((r) => r['hallazgos_especificos']?.toString() ?? '')
            .where((h) => h.isNotEmpty)
            .join('; ');
      }
    }

    // 4. Cargar imagen de portada
    final img = await rootBundle.load('assets/portada.webp');
    final portada = img.buffer.asUint8List();

    // 5. Crear documento PDF
    final pdf = pw.Document();

    // Hoja 1 - Portada
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned.fill(
              child: pw.Image(pw.MemoryImage(portada), fit: pw.BoxFit.cover),
            ),
            pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('REPORTE DE EXCELENCIA OPERACIONAL', style: pw.TextStyle(fontSize: 26, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                  pw.SizedBox(height: 20),
                  pw.Text('Organización: $organizacion', style: pw.TextStyle(fontSize: 16, color: PdfColors.white)),
                  pw.SizedBox(height: 8),
                  pw.Text('Localización: $localizacion', style: pw.TextStyle(fontSize: 16, color: PdfColors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Hoja 2 en blanco
    pdf.addPage(pw.Page(build: (_) => pw.Container()));

    // Hoja 3+ - contenido dinámico
    for (final entry in reportJson.entries) {
      final comportamiento = entry.key;
      final datos = entry.value as JsonMap;
      final desc = datos['descripcion'] as String? ?? '';
      final niveles = (datos['niveles'] as List).cast<JsonMap>();

      // Gráfico inline
      final chart = pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
        children: niveles.map((n) {
          final v = double.tryParse(n['resultado']?.toString() ?? '') ?? 0.0;
          return pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(border: pw.Border.all()),
            child: pw.Center(child: pw.Text(v.toStringAsFixed(1), style: pw.TextStyle(fontSize: 8))),
          );
        }).toList(),
      );

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(16),
          build: (_) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(comportamiento.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              if (desc.isNotEmpty) pw.Padding(padding: pw.EdgeInsets.only(bottom: 8), child: pw.Text(desc)),
              // ignore: deprecated_member_use
              pw.Table.fromTextArray(
                headers: ['Nivel','Resultado','Interpretación','Sistemas','Hallazgos','Benchmark','Gráfico'],
                data: niveles.map((n) => [
                  n['nivel'],
                  n['resultado'],
                  n['interpretacion_comportamiento'],
                  n['sistemas_asociados'],
                  n['hallazgos_especificos'],
                  n['benchmark'],
                  chart,
                ]).toList(),
                cellAlignment: pw.Alignment.topLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                cellStyle: pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
      );
    }

    return pdf.save();
  }
}
