import 'package:applensys/charts/scatter_bubble_chart.dart';
import 'package:applensys/models/comportamiento.dart';
import 'package:applensys/models/principio.dart';
import 'package:applensys/models/dimension.dart';

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
            cargo: comp['nivel'] ?? '',
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
}
