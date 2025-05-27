// Servicio para alimentar EvaluationCarousel con datos estructurados desde caché o Supabase
import 'dart:math';
import 'package:applensys/models/level_averages.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

const List<String> dimensionesFijas = [
  'Impulsores culturales',
  'Mejora continua',
  'Alineamiento empresarial',
];

const List<String> comportamientosFijos = [
  'Soporte',
  'Reconocimiento',
  'Comunidad',
  'Liderazgo de servidor',
  'Valorar',
  'Empoderamiento',
  'Mentalidad',
  'Estructura',
  'Reflexionar',
  'Análisis',
  'Colaborar',
  'Comprender',
  'Diseño',
  'Atribución',
  'A prueba de error',
  'Propiedad',
  'Conectar',
  'Ininterrumpido',
  'Demanda',
  'Eliminar',
  'Optimizar',
  'Impacto',
  'Alinear',
  'Aclarar',
  'Comunicar',
  'Relación',
  'Valor',
  'Medida',
];

class EvaluationChartDataService {
  final EvaluacionCacheService _cacheService = EvaluacionCacheService();

  ChartsDataModel procesarDatos(List<Map<String, dynamic>> datos) {
    return ChartsDataModel(
      dimensionPromedios: _calcularPromedios(datos),
      lineChartData: _generarLevelAverages(datos), // Usar el método renombrado y modificado
      comportamientoPorNivel: _generarGroupedBar(datos),
      sistemasPorNivel: _generarHorizontalBar(datos),
      scatterData: _generarScatter(datos),
    );
  }

  Map<String, double> _calcularPromedios(List<Map<String, dynamic>> datos) {
    final Map<String, double> dimensionPromedios = {};
    final Map<String, double> sumasPorDimension = {};
    final Map<String, int> conteosPorDimension = {};

    for (var item in datos) {
      final dimension = item['dimension']?.toString() ?? '';
      final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;

      sumasPorDimension[dimension] = (sumasPorDimension[dimension] ?? 0) + valor;
      conteosPorDimension[dimension] = (conteosPorDimension[dimension] ?? 0) + 1;
    }

    sumasPorDimension.forEach((dimension, suma) {
      final conteo = conteosPorDimension[dimension] ?? 1;
      dimensionPromedios[dimension] = suma / conteo;
    });

    return dimensionPromedios;
  }

  // Método renombrado y modificado para devolver List<LevelAverages>
  List<LevelAverages> _generarLevelAverages(List<Map<String, dynamic>> datos) {
    final Map<String, Map<String, List<double>>> datosPorDimensionYNivel = {};

    for (var item in datos) {
      final dimension = item['dimension']?.toString();
      final valor = (item['valor'] as num?)?.toDouble();
      final rawNivel = (item['cargo_raw'] as String?)?.toLowerCase().trim();

      if (dimension == null || valor == null || rawNivel == null) continue;

      final String? nivel;
      if (rawNivel.contains('miembro')) {
        nivel = 'Miembro';
      } else if (rawNivel.contains('gerente')) {
        nivel = 'Gerente';
      } else if (rawNivel.contains('ejecutivo')) {
        nivel = 'Ejecutivo';
      } else {
        nivel = null;
      }

      if (nivel == null) continue;

      datosPorDimensionYNivel.putIfAbsent(dimension, () => {});
      datosPorDimensionYNivel[dimension]!.putIfAbsent(nivel, () => []).add(valor);
    }

    final List<LevelAverages> levelAveragesList = [];
    int idCounter = 0;

    for (var dimension in dimensionesFijas) {
      final Map<String, List<double>>? nivelesData = datosPorDimensionYNivel[dimension];

      double calcAverage(List<double>? values) {
        if (values == null || values.isEmpty) return 0.0;
        return values.reduce((a, b) => a + b) / values.length;
      }

      final ejecutivoAvg = calcAverage(nivelesData?['Ejecutivo']);
      final gerenteAvg = calcAverage(nivelesData?['Gerente']);
      final miembroAvg = calcAverage(nivelesData?['Miembro']);

      levelAveragesList.add(LevelAverages(
        id: idCounter++,
        nombre: dimension,
        ejecutivo: ejecutivoAvg,
        gerente: gerenteAvg,
        miembro: miembroAvg,
        nivel: '', 
      ));
    }
    return levelAveragesList;
  }

  Map<String, List<double>> _generarGroupedBar(List<Map<String, dynamic>> datos) {
    final Map<String, List<double>> comportamientoPorNivel = {
      'Ejecutivo': List.filled(comportamientosFijos.length, 0.0),
      'Gerente': List.filled(comportamientosFijos.length, 0.0),
      'Miembro': List.filled(comportamientosFijos.length, 0.0),
    };

    for (var item in datos) {
      final comportamiento = item['comportamiento']?.toString() ?? '';
      final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
      final rawNivel = (item['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
      final nivel = rawNivel.contains('miembro') ? 'Miembro'
                  : rawNivel.contains('gerente') ? 'Gerente'
                  : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                  : null;
      if (nivel == null) continue;

      final comportamientoIndex = comportamientosFijos.indexOf(comportamiento);
      if (comportamientoIndex >= 0) {
        comportamientoPorNivel[nivel]![comportamientoIndex] = valor;
      }
    }

    return comportamientoPorNivel;
  }

  Map<String, Map<String, double>> _generarHorizontalBar(List<Map<String, dynamic>> datos) {
    final Map<String, Map<String, double>> sistemasPorNivel = {};

    for (var item in datos) {
      final sistemas = (item['sistemas'] as List?)?.cast<String>() ?? [];
      final rawNivel = (item['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
      final nivel = rawNivel.contains('miembro') ? 'Miembro'
                  : rawNivel.contains('gerente') ? 'Gerente'
                  : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                  : null;
      if (nivel == null) continue;

      for (final sistema in sistemas) {
        sistemasPorNivel.putIfAbsent(sistema, () => {
          'Ejecutivo': 0,
          'Gerente': 0,
          'Miembro': 0,
        });
        sistemasPorNivel[sistema]![nivel] = (sistemasPorNivel[sistema]![nivel] ?? 0) + 1;
      }
    }
    return sistemasPorNivel;
  }

  List<ScatterData> _generarScatter(List<Map<String, dynamic>> datos) {
    final List<ScatterData> scatterData = [];

    for (var item in datos) {
      final comportamiento = item['comportamiento']?.toString() ?? ''; // Asumiendo que es 'comportamiento' y no 'principio'
      final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
      final rawNivel = (item['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
      final nivel = rawNivel.contains('miembro') ? 'Miembro'
                  : rawNivel.contains('gerente') ? 'Gerente'
                  : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                  : null;
      if (nivel == null) continue;

      scatterData.add(ScatterData(comportamiento, valor, nivel));
    }
    return scatterData;
  }

  Future<ChartsDataModel> cargarDatosParaGraficas(String evaluacionId) async {
    final tablaDatos = await _cacheService.cargarTablas();
    final List<Map<String, dynamic>> datosFiltrados = [];
    tablaDatos.forEach((dimension, evaluacionMap) {
      final List<Map<String, dynamic>>? listaItems = evaluacionMap[evaluacionId];
      if (listaItems != null) {
        for (var item in listaItems) {
          final newItem = Map<String, dynamic>.from(item);
          newItem['dimension'] = dimension; 
          datosFiltrados.add(newItem);
        }
      }
    });
    
    return procesarDatos(datosFiltrados); // Reutilizar procesarDatos con los datos filtrados
  }

  void limpiarDatos() {
    // Implementar lógica para limpiar datos de caché o Supabase
  }
}

class ChartsDataModel {
  final Map<String, double> dimensionPromedios;
  final List<LevelAverages> lineChartData; // Asegurado que es List<LevelAverages>
  final List<ScatterData> scatterData;
  final Map<String, Map<String, double>> sistemasPorNivel;
  final Map<String, List<double>> comportamientoPorNivel;

  ChartsDataModel({
    required this.dimensionPromedios,
    required this.lineChartData,
    required this.scatterData,
    required this.sistemasPorNivel,
    required this.comportamientoPorNivel,
  });
}

class ScatterData {
  final String principio; // O 'comportamiento' según la lógica de _generarScatter
  final double valor;
  final String nivel;

  ScatterData(this.principio, this.valor, this.nivel);
}

// La clase LineChartSerie se elimina ya que no se usa más
// class LineChartSerie {
//   final String dimension;
//   final String nivel;
//   final double promedio;
//
//   LineChartSerie({
//     required this.dimension,
//     required this.nivel,
//     required this.promedio,
//   });
// }

