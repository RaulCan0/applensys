import 'dart:math';
import 'package:applensys/models/level_averages.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';




class EvaluationChartDataService {

  Future<ChartsDataModel> cargarDatosParaGraficas(String evaluacionId) async {
    final evaluacionCacheService = EvaluacionCacheService();
    final tablaDatos = await evaluacionCacheService.cargarTablas();

    final Map<String, double> dimensionPromedios = {};
    final List<LevelAverages> lineChartData = [];
    final List<ScatterData> scatterData = [];
    final Map<String, Map<String, double>> sistemasPorNivel = {};
    final Map<String, List<double>> comportamientoPorNivel = {
      'Ejecutivo': List.filled(28, 0),
      'Gerente': List.filled(28, 0),
      'Miembro': List.filled(28, 0),
    };
const List<String> dimensionesFijas = [
  'Impulsores culturales',
  'Mejora continua',
  'Alineamiento empresarial',
];

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
    
const List<String> comportamientosFijos = [
  'Soporte',
  'Reconocer',
  'Comunidad',
  'Liderazgo de Servidor',
  'Valorar',
  'Empoderar',
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
 final sistemasOrdenados = [
      'Ambiental',
      'Comunicación',
      'Desarrollo de personal',
      'Despliegue de estrategia',
      'Gestion visual',
      'Involucramiento',
      'Medicion',
      'Mejora y alineamiento estratégico',
      'Mejora y gestion visual',
      'Planificacion',
      'Programacion y de mejora',
      'Reconocimiento',
      'Seguridad',
      'Sistemas de mejora',
      'Solucion de problemas',
      'Voz de cliente',
      'Visitas al Gemba'
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
    for (var dimension in tablaDatos.keys) {
      tablaDatos[dimension]?.forEach((_, lista) {
        for (var item in lista) {
          final rawNivel = (item['cargo'] as String?)?.toLowerCase().trim() ?? '';
          final nivel = rawNivel.contains('miembro') ? 'Miembro'
                      : rawNivel.contains('gerente') ? 'Gerente'
                      : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                      : null;
          if (nivel == null) continue;
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
          }
      });
    }
    return ChartsDataModel(
      dimensionPromedios: dimensionPromedios,
      lineChartData: lineChartData,
      scatterData: scatterData,
      sistemasPorNivel: sistemasPorNivel,
      comportamientoPorNivel: comportamientoPorNivel,
    );
  }

  void limpiarDatos() {
  }
}

class ChartsDataModel {
  final Map<String, double> dimensionPromedios;
  final List<LevelAverages> lineChartData;
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
  final String principio;
  final double valor;
  final String nivel;

  ScatterData(this.principio, this.valor, this.nivel);
}

class PrincipiosChart extends StatelessWidget {
  final List<String> principios;
  final List<List<double>> valores;

  const PrincipiosChart({
    super.key,
    required this.principios,
    required this.valores,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 5,
          barGroups: List.generate(principios.length, (index) {
            return BarChartGroupData(
              x: index,
              barRods: List.generate(3, (i) {
                return BarChartRodData(
                  toY: valores[index][i],
                  color: i == 0
                      ? Colors.red
                      : i == 1
                          ? Colors.green
                          : Colors.blue,
                  width: 8,
                );
              }),
            );
          }),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, interval: 1),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= principios.length) return const SizedBox.shrink();
                  return Text(principios[index], style: const TextStyle(fontSize: 10));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}/*

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

  ChartsDataModel procesarDatos(List<Map<String, dynamic>> data) {
    final Map<String, double> dimensionPromedios = {};
    final List<LevelAverages> lineChartData = [];
    final List<ScatterData> scatterData = [];
    final Map<String, Map<String, int>> sistemasPorNivel = {};
    final Map<String, List<double>> comportamientoPorNivel = {
      'Ejecutivo': List.filled(comportamientosFijos.length, 0),
      'Gerente': List.filled(comportamientosFijos.length, 0),
      'Miembro': List.filled(comportamientosFijos.length, 0),
    };

    // Mapas auxiliares para cálculos de promedios
    final Map<String, double> sumasPorDimension = {};
    final Map<String, int> conteosPorDimension = {};
    final Map<String, Map<String, double>> sumasPorNivel = {
      'Ejecutivo': {},
      'Gerente': {},
      'Miembro': {},
    };
    final Map<String, Map<String, int>> conteosPorNivel = {
      'Ejecutivo': {},
      'Gerente': {},
      'Miembro': {},
    };

    for (var item in data) {
      final dimension = item['dimension']?.toString() ?? '';
      final comportamiento = item['comportamiento']?.toString() ?? '';
      final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
      final rawNivel = (item['cargo_raw'] as String?)?.toLowerCase().trim() ?? '';
      final sistemas = (item['sistemas'] as List?)?.cast<String>() ?? [];
      
      // Normalizar nivel
      final nivel = rawNivel.contains('miembro') ? 'Miembro'
                  : rawNivel.contains('gerente') ? 'Gerente'
                  : rawNivel.contains('ejecutivo') ? 'Ejecutivo'
                  : null;
      if (nivel == null) continue;

      // Actualizar sumas y conteos por dimensión
      sumasPorDimension[dimension] = (sumasPorDimension[dimension] ?? 0) + valor;
      conteosPorDimension[dimension] = (conteosPorDimension[dimension] ?? 0) + 1;

      // Actualizar datos para gráficos de línea
      sumasPorNivel[nivel]![dimension] = (sumasPorNivel[nivel]![dimension] ?? 0) + valor;
      conteosPorNivel[nivel]![dimension] = (conteosPorNivel[nivel]![dimension] ?? 0) + 1;

      // Actualizar sistemas por nivel
      for (final sistema in sistemas) {
        sistemasPorNivel.putIfAbsent(sistema, () => {
          'Ejecutivo': 0,
          'Gerente': 0,
          'Miembro': 0,
        });
        sistemasPorNivel[sistema]![nivel] = (sistemasPorNivel[sistema]![nivel] ?? 0) + 1;
      }

      // Actualizar datos de comportamientos por nivel
      final comportamientoIndex = comportamientosFijos.indexOf(comportamiento);
      if (comportamientoIndex >= 0) {
        comportamientoPorNivel[nivel]![comportamientoIndex] = valor;
      }

      // Generar datos para gráfico de dispersión
      scatterData.add(ScatterData(comportamiento, valor, nivel));
    }

    // Calcular promedios por dimensión
    sumasPorDimension.forEach((dimension, suma) {
      final conteo = conteosPorDimension[dimension] ?? 1;
      dimensionPromedios[dimension] = suma / conteo;
    });

    // Generar datos para gráfico de línea
    for (var dimension in dimensionesFijas) {
      sumasPorNivel.forEach((nivel, sumas) {
        final suma = sumas[dimension] ?? 0;
        final conteo = conteosPorNivel[nivel]![dimension] ?? 1;
        final promedio = suma / conteo;
        
        lineChartData.add(LevelAverages(
          id: lineChartData.length + 1,
          nombre: dimension,
          ejecutivo: nivel == 'Ejecutivo' ? promedio : 0,
          gerente: nivel == 'Gerente' ? promedio : 0,
          miembro: nivel == 'Miembro' ? promedio : 0,
          dimensionId: dimensionesFijas.indexOf(dimension) + 1,
          general: promedio,
          nivel: nivel,
        ));
      });
    }

    return ChartsDataModel(
      dimensionPromedios: dimensionPromedios,
      lineChartData: lineChartData,
      scatterData: scatterData,
      sistemasPorNivel: sistemasPorNivel,
      comportamientoPorNivel: comportamientoPorNivel,
    );
  }

  Future<ChartsDataModel> cargarDatosParaGraficas(String evaluacionId) async {
    final evaluacionCacheService = EvaluacionCacheService();
    final tablaDatos = await evaluacionCacheService.cargarTablas();

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
}*/

