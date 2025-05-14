import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

import 'package:applensys/providers/app_provider.dart';

/// Genera un prereporte en formato .docx (editable)
/// usando una plantilla interna de PDF convertido a DOCX.
class PrereporteGenerator {
  /// Genera el prereporte y retorna los bytes del documento.
  ///
  /// [appProv]: instancia de AppProvider para extraer promedios y datos.
  /// [evaluacionId]: ID de la evaluación actual.
  /// [sistemasPorNivel]: mapa nivel:comportamiento → lista de sistemas.
  Future<Uint8List> generateDocx({
    required AppProvider appProv,
    required String evaluacionId,
    required Map<String, List<String>> sistemasPorNivel,
    // Opcional: rutas a tus JSON si las necesitas dinámicas
  }) async {
    final doc = pw.Document();

    // 1) Cargar JSON de la estructura y benchmarks
    final estructuraRaw = await rootBundle.loadString('assets/json/estructura_base.json');
    final t1Raw = await rootBundle.loadString('assets/json/t1.json');
    final t2Raw = await rootBundle.loadString('assets/json/t2.json');
    final t3Raw = await rootBundle.loadString('assets/json/t3.json');

    final estructura = json.decode(estructuraRaw) as Map<String, dynamic>;
    final bench1 = (json.decode(t1Raw) as List).cast<Map<String, dynamic>>();
    final bench2 = (json.decode(t2Raw) as List).cast<Map<String, dynamic>>();
    final bench3 = (json.decode(t3Raw) as List).cast<Map<String, dynamic>>();

    // Auxiliares para texto y benchmark por nivel
    String textoResultado(String comp, String nivel, int value) {
      final list = (nivel == '1' ? bench1 : nivel == '2' ? bench2 : bench3)
          .firstWhere(
            (e) => (e['BENCHMARK DE COMPORTAMIENTOS'] as String).startsWith(comp),
            orElse: () => {},
          )['C$value'];
      return list?.toString() ?? '';
    }

    String benchmarkPorNivel(String comp, String nivel) {
      final entry = (nivel == '1' ? bench1 : nivel == '2' ? bench2 : bench3)
          .firstWhere(
            (e) => (e['BENCHMARK DE COMPORTAMIENTOS'] as String).startsWith(comp),
            orElse: () => {},
          );
      return entry['BENCHMARK POR NIVEL']?.toString() ?? '';
    }

    // 2) Iterar dimensiones → principios → comportamientos
    for (final dim in (estructura['dimensiones'] as List)) {
      doc.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (ctx) {
            final rows = <List<dynamic>>[];
            // Encabezado
            rows.add([
              'Comportamiento',
              'Ejecutivo',
              'Gerente',
              'Equipo',
              'Sist. Ejec.',
              'Sist. Ger.',
              'Sist. Equipo',
              'Resultado',
              'Benchmark Nivel',
            ]);

            for (final princ in (dim['principios'] as List)) {
              for (final comp in (princ['comportamientos'] as List).cast<String>()) {
                // Obtener promedios redondeados
                final pe = appProv.getPromedio(dim['id'].toString(), comp, '1').round();
                final pg = appProv.getPromedio(dim['id'].toString(), comp, '2').round();
                final pm = appProv.getPromedio(dim['id'].toString(), comp, '3').round();

                // Sistemas por nivel
                final se = sistemasPorNivel['1:$comp'] ?? [];
                final sg = sistemasPorNivel['2:$comp'] ?? [];
                final sm = sistemasPorNivel['3:$comp'] ?? [];

                rows.add([
                  comp,
                  pe,
                  pg,
                  pm,
                  se.join(', '),
                  sg.join(', '),
                  sm.join(', '),
                  textoResultado(comp, '1', pe),
                  benchmarkPorNivel(comp, '1'),
                ]);
              }
            }

            return [
              pw.Header(level: 1, text: dim['nombre'].toString()),
              pw.TableHelper.fromTextArray(
                headers: rows.first,
                data: rows.skip(1).toList(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FixedColumnWidth(40),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FixedColumnWidth(40),
                },
              ),
            ];
          },
        ),
      );
    }

    // 3) Devolver bytes generados
    return doc.save();
  }
}
