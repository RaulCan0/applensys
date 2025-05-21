import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/level_averages.dart';

/// Servicio para exportar promedios a un Excel basado en plantilla.
class ExcelExporter {
  static const String _templatePath = 'assets/correlacion shingo.xlsx';

  /// Rellena (o crea) la hoja 'Datos Lensys' con tus promedios
  /// de comportamientos y sistemas, y guarda el archivo.
  static Future<File> export({
    required List<LevelAverages> behaviorAverages,
    required List<LevelAverages> systemAverages,
  }) async {
    // Cargar bytes de la plantilla
    final bytes = (await rootBundle.load(_templatePath)).buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    // Borrar hoja existente si aplica
    if (excel.sheets.containsKey('Datos Lensys')) {
      excel.delete('Datos Lensys');
    }
    // Crear hoja nueva
    final sheet = excel['Datos Lensys'];

    int rowIndex = 0;
    // Encabezados
    final headers = ['Tipo', 'Nombre', 'Ejecutivo', 'Gerente', 'Miembro'];
    for (var col = 0; col < headers.length; col++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIndex),
        headers[col] as CellValue?,
      );
    }

    // Datos de comportamientos
    for (var i = 0; i < behaviorAverages.length; i++) {
      final b = behaviorAverages[i];
      final r = rowIndex + 1 + i;
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), 'Comportamiento' as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r), b.nombre as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r), b.ejecutivo as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r), b.gerente as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r), b.miembro as CellValue?);
    }

    // Datos de sistemas asociados (inician después de comportamientos)
    for (var j = 0; j < systemAverages.length; j++) {
      final s = systemAverages[j];
      final r = rowIndex + 1 + behaviorAverages.length + j;
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r), 'Sistema Asociado' as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: r), s.nombre as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: r), s.ejecutivo as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: r), s.gerente as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: r), s.miembro as CellValue?);
    }

    // Guardar en dispositivo
    final dir = await getApplicationDocumentsDirectory();
    final file = File('\${dir.path}/Lensys_Report.xlsx');
    final encoded = excel.encode();
    if (encoded == null) throw Exception('Error al codificar Excel');
    await file.writeAsBytes(encoded, flush: true);
    return file;
  }
}
