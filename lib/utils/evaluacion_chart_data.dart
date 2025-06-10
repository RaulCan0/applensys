import 'package:applensys/charts/scatter_bubble_chart.dart';
import 'package:applensys/models/comportamiento.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/dimension.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

class EvaluacionChartData {
  static List<Dimension> buildDimensionesChartData(List<Map<String, dynamic>> dimensionesRaw) {
    return dimensionesRaw.map((dim) {
      List<Principio> principios = (dim['principios'] as List).map((pri) {
        List<Comportamiento> comportamientos = (pri['comportamientos'] as List).map((comp) {
          return Comportamiento(
            nombre: comp['nombre'],
            promedioEjecutivo: (comp['ejecutivo'] ?? 0.0).toDouble(),
            promedioGerente: (comp['gerente'] ?? 0.0).toDouble(),
            promedioMiembro: (comp['miembro'] ?? 0.0).toDouble(),
            sistemas: List<String>.from(comp['sistemas'] ?? []),
            cargo: comp['cargo'] ?? '',
            nivel: null,
            principioId: '',
            id: '',
          );
        }).toList();

        return Principio(
          id: pri['id'] ?? '',
          dimensionId: dim['id'] ?? '',
          nombre: pri['nombre'],
          promedioGeneral: (pri['promedio'] ?? 0.0).toDouble(),
          comportamientos: comportamientos,
        );
      }).toList();

      return Dimension(
        id: dim['id'].toString(),
        nombre: dim['nombre'],
        promedioGeneral: (dim['promedio'] ?? 0.0).toDouble(),
        principios: principios,
      );
    }).toList();
  }

  static List<Principio> extractPrincipios(List<Dimension> dimensiones) {
    return dimensiones.expand((d) => d.principios).toList();
  }

  static List<Comportamiento> extractComportamientos(List<Dimension> dimensiones) {
    return dimensiones
        .expand((d) => d.principios)
        .expand((p) => p.comportamientos)
        .toList();
  }
Future<List<Map<String, dynamic>>> cargarPromediosSistemas() async {
  // 1) Usamos EvaluacionCacheService en lugar de TablaDatos
  final tabla = await EvaluacionCacheService().cargarTablas();
  final Map<String, List<double>> acumulador = {};

  tabla.forEach((_, submap) {
    submap.values.expand((rows) => rows).forEach((item) {
      // Asegúrate de que 'sistema' y 'valor' existan en cada item
      final sistema = item['sistema'] as String? ?? '';
      final raw     = item['valor'];

      final valor = raw is num
          ? raw.toDouble()
          : double.tryParse(raw.toString()) ?? 0.0;

      if (sistema.isNotEmpty) {
        acumulador.putIfAbsent(sistema, () => []).add(valor);
      }
    });
  });

  return acumulador.entries.map((e) {
    final lista    = e.value;
    final suma     = lista.fold<double>(0, (a, b) => a + b);
    final promedio = lista.isNotEmpty ? suma / lista.length : 0.0;
    return {
      'sistema': e.key,
      'valor'  : promedio,
    };
  }).toList();
}
}