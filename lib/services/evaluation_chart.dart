import 'dart:math';
import 'package:applensys/models/level_averages.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

  Future<ChartsDataModel> cargarDatosParaGraficas(String evaluacionId) async {
    final evaluacionCacheService = EvaluacionCacheService();
    final tablaDatos = await evaluacionCacheService.cargarTablas();

    final Map<String, double> dimensionPromedios = {};
    final List<LevelAverages> lineChartData = [];
    final List<ScatterData> scatterData = [];
    final Map<String, Map<String, int>> sistemasPorCargo = {};
    final Map<String, List<double>> comportamientoPorCargo = {
      'Ejecutivo': List.filled(28, 0),
      'Gerente': List.filled(28, 0),
      'Miembro': List.filled(28, 0),
    };

    // NUEVO: Suma y conteo para promedios por sistema y cargo
    final Map<String, Map<String, double>> sumaPorSistemaCargo = {};
    final Map<String, Map<String, int>> conteoPorSistemaCargo = {};

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

    // Preparar datos adicionales (normalizar cargos y contar sistemas)
    for (var dimension in tablaDatos.keys) {
      tablaDatos[dimension]?.forEach((_, lista) {
        for (var item in lista) {
          final rawCargo = (item['cargo'] as String?)?.toLowerCase().trim() ?? '';
          final cargo = rawCargo.contains('miembro')
              ? 'Miembro'
              : rawCargo.contains('gerente')
                  ? 'Gerente'
                  : rawCargo.contains('ejecutivo')
                      ? 'Ejecutivo'
                      : null;
          if (cargo == null) continue;

          final valor = (item['valor'] as num?)?.toDouble() ?? 0.0;
          final sistemas = (item['sistemas'] as List?)?.cast<String>() ?? [];

          // Sumar y contar por sistema y cargo
          for (final sistema in sistemas) {
            sumaPorSistemaCargo.putIfAbsent(sistema, () => {'Ejecutivo': 0.0, 'Gerente': 0.0, 'Miembro': 0.0});
            conteoPorSistemaCargo.putIfAbsent(sistema, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
            sumaPorSistemaCargo[sistema]![cargo] = (sumaPorSistemaCargo[sistema]![cargo] ?? 0) + valor;
            conteoPorSistemaCargo[sistema]![cargo] = (conteoPorSistemaCargo[sistema]![cargo] ?? 0) + 1;
          }

          // Sistemas por cargo
          for (final sistema in sistemas) {
            sistemasPorCargo.putIfAbsent(sistema, () => {
              'Ejecutivo': 0,
              'Gerente': 0,
              'Miembro': 0,
            });
            sistemasPorCargo[sistema]![cargo] =
                (sistemasPorCargo[sistema]![cargo] ?? 0) + 1;
          }

          // Aquí podrías calcular scatterData y lineChartData usando 'cargo'
          // Ejemplo de scatterData:
          // scatterData.add(ScatterData(
          //   principio: item['principio'],
          //   valor: (item['valor'] as num?)?.toDouble() ?? 0,
          //   cargo: cargo,
          // ));

          // Otros cálculos para comportamientoPorCargo...
        }
      });
    }

    // Calcular promedios por sistema y cargo
    final Map<String, Map<String, double>> promedioPorSistemaCargo = {};
    sumaPorSistemaCargo.forEach((sistema, cargos) {
      promedioPorSistemaCargo[sistema] = {};
      cargos.forEach((cargo, suma) {
        final count = conteoPorSistemaCargo[sistema]![cargo]!;
        promedioPorSistemaCargo[sistema]![cargo] = count > 0 ? suma / count : 0.0;
      });
    });

    // Puedes retornar este mapa o usarlo en tus gráficos
    // Ejemplo: print(promedioPorSistemaCargo);

    return ChartsDataModel(
      dimensionPromedios: dimensionPromedios,
      lineChartData: lineChartData,
      scatterData: scatterData,
      sistemasPorCargo: sistemasPorCargo,
      comportamientoPorCargo: comportamientoPorCargo,
      // Si quieres, agrega promedioPorSistemaCargo como nuevo campo en ChartsDataModel
    );
  }

  void limpiarDatos() {
    // Lógica para limpiar datos de caché o Supabase
  }
}

class ChartsDataModel {
  final Map<String, double> dimensionPromedios;
  final List<LevelAverages> lineChartData;
  final List<ScatterData> scatterData;
  final Map<String, Map<String, int>> sistemasPorCargo;
  final Map<String, List<double>> comportamientoPorCargo;

  ChartsDataModel({
    required this.dimensionPromedios,
    required this.lineChartData,
    required this.scatterData,
    required this.sistemasPorCargo,
    required this.comportamientoPorCargo,
  });
}

class ScatterData {
  final String principio;
  final double valor;
  final String cargo;

  ScatterData(this.principio, this.valor, this.cargo);
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
}
