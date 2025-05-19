// Servicio para alimentar EvaluationCarousel con datos estructurados desde caché o Supabase
import 'dart:math';
import 'package:applensys/models/level_averages.dart';
import 'package:applensys/services/evaluacion_cache_service.dart';

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

  Future<ChartsDataModel> cargarDatosParaGraficas(String evaluacionId) async {
    final tablaDatos = await _cacheService.cargarTablas();

    final Map<String, double> dimensionPromedios = {};
    final List<LevelAverages> lineChartData = [];
    final List<ScatterData> scatterData = [];
    final Map<String, Map<String, int>> sistemasPorNivel = {};
    final Map<String, List<double>> comportamientoPorNivel = {
      'Ejecutivo': List.filled(28, 0),
      'Gerente': List.filled(28, 0),
      'Miembro': List.filled(28, 0),
    };

    final List<String> principios = [
      'Respetar a cada individuo',
      'Liderar con humildad',
      'Buscar la perfección',
      'Abrazar el pensamiento científico',
      'Enfocarse en el proceso',
      'Asegurar la calidad en la fuente',
      'Mejorar el flujo y jalón de valor',
      'Pensar sistémicamente',
      'Crear constancia en el propósito',
      'Crear valor para el cliente'
    ];

    // Cargar promedios por dimensión
    for (var dimension in tablaDatos.keys) {
      double suma = 0;
      int conteo = 0;
      tablaDatos[dimension]?.forEach((_, lista) {
        for (var item in lista) {
          final valor = (item['valor'] as num?)?.toDouble() ?? 0;
          suma += valor;
          conteo++;
        }
      });
      dimensionPromedios[dimension] = conteo > 0 ? suma / conteo : 0;
    }

    // Preparar datos adicionales (este bloque se ampliará en los siguientes pasos)
    // Normalizar los niveles: 'Miembro de equipo' -> 'Miembro'
    for (var dimension in tablaDatos.keys) {
      tablaDatos[dimension]?.forEach((_, lista) {
        for (var item in lista) {
          final rawNivel = (item['cargo'] as String?)?.toLowerCase().trim() ?? '';
          final nivel = rawNivel.contains('miembro') ? 'Miembro'
                      : rawNivel.contains('gerente') ? 'Gerente'
                      : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                      : null;
          if (nivel == null) continue;

          // Aquí se pueden construir: lineChartData, scatterData, sistemasPorNivel, etc.
          // Ejemplo para sistemas:
          final sistemas = (item['sistemas'] as List?)?.cast<String>() ?? [];
          for (final sistema in sistemas) {
            sistemasPorNivel.putIfAbsent(sistema, () => {
              'Ejecutivo': 0,
              'Gerente': 0,
              'Miembro': 0,
            });
            sistemasPorNivel[sistema]![nivel] =
              (sistemasPorNivel[sistema]![nivel] ?? 0) + 1;
          }

          // Otros cálculos... (comportamientos, promedios, etc.)
        }
      });
    }
    // ...

    return ChartsDataModel(
      dimensionPromedios: dimensionPromedios,
      lineChartData: lineChartData,
      scatterData: scatterData,
      sistemasPorNivel: sistemasPorNivel,
      comportamientoPorNivel: comportamientoPorNivel,
    );
  }

  void limpiarDatos() {
    // Implementar lógica para limpiar datos de caché o Supabase
  }
}

class ChartsDataModel {
  final Map<String, double> dimensionPromedios;
  final List<LevelAverages> lineChartData;
  final List<ScatterData> scatterData;
  final Map<String, Map<String, int>> sistemasPorNivel;
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
  final String principio;
  final double valor;
  final String nivel;

  ScatterData(this.principio, this.valor, this.nivel);
}

