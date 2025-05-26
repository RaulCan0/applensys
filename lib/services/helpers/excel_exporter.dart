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
    // 1. Cargar bytes de la plantilla
    final data = await rootBundle.load(_templatePath);
    final bytes = data.buffer.asUint8List();
    final excel = Excel.decodeBytes(bytes);

    // 2. Eliminar la hoja previa (si existía) y crearla de nuevo
    if (excel.sheets.containsKey('Datos Lensys')) {
      excel.delete('Datos Lensys');
    }
    final Sheet sheet = excel['Datos Lensys'];

    // 3. Encabezados
    final headers = ['Tipo', 'Nombre', 'Ejecutivo', 'Gerente', 'Miembro'];
    for (var col = 0; col < headers.length; col++) {
      sheet.updateCell(
        CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0),
        headers[col] as CellValue?,
      );
    }

    // 4. Datos de comportamientos
    for (var i = 0; i < behaviorAverages.length; i++) {
      final row = i + 1;
      final b = behaviorAverages[i];
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 'Comportamiento' as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row), b.nombre as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), b.ejecutivo as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row), b.gerente as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row), b.miembro as CellValue?);
    }

    // 5. Datos de sistemas asociados
    final startRow = behaviorAverages.length + 1;
    for (var j = 0; j < systemAverages.length; j++) {
      final row = startRow + j;
      final s = systemAverages[j];
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row), 'Sistema Asociado' as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row), s.nombre as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row), s.ejecutivo as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row), s.gerente as CellValue?);
      sheet.updateCell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row), s.miembro as CellValue?);
    }

    // 6. Guardar el archivo en documentos
    final dir = await getApplicationDocumentsDirectory();
    final outFile = File('${dir.path}/Lensys_Report.xlsx');
    final fileBytes = excel.encode();
    if (fileBytes == null) {
      throw Exception('Error al codificar el Excel');
    }
    await outFile.writeAsBytes(fileBytes, flush: true);

    return outFile;
  }
}
