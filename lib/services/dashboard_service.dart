// ignore_for_file: empty_constructor_bodies, curly_braces_in_flow_control_structures

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de métricas del dashboard
class DashboardMetrics {
  final Map<String, double> promedioPorDimension;
  final Map<String, int> conteoPorDimension;
  final Map<String, Map<String, double>> sistemasPorNivel;
  final Map<String, Map<String, double>> principiosPorNivel;
  final Map<String, Map<String, double>> comportamientosPorNivel;

  DashboardMetrics({
    required this.promedioPorDimension,
    required this.conteoPorDimension,
    required this.sistemasPorNivel,
    required this.principiosPorNivel,
    required this.comportamientosPorNivel,
  });
}

/// Servicio para alimentar datos del dashboard de forma incremental
typedef DashboardListener = void Function(DashboardMetrics metrics);

class DashboardService {
  final SupabaseClient _client = Supabase.instance.client;
  final String empresaId;
  late final StreamSubscription _subscription;

  DashboardService(this.empresaId);

  /// Inicia el servicio y suscribe a cambios en calificaciones
  Future<void> start(DashboardListener onUpdate) async {
    // Carga inicial
    await _fetchAndNotify(onUpdate);

    // Suscribe a real-time para nueva calificación
    _subscription = _client
        .from('calificaciones')
        .stream(primaryKey: ['id'])
        .eq('id_empresa', empresaId)
        // ignore: deprecated_member_use
        .execute()
        .listen((_) async {
      await _fetchAndNotify(onUpdate);
    });
  }

  /// Detiene la suscripción
  Future<void> dispose() async {
    await _subscription.cancel();
  }

  Future<String> generateDimensionJson(String dimensionId) async {
    const String selectColumns = 'id, id_asociado, id_empresa, id_dimension, comportamiento, puntaje, fecha_evaluacion, observaciones, sistemas, evidencia_url';
    final records = await _client
        .from('calificaciones')
        .select(selectColumns)
        .eq('id_empresa', empresaId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 0);
    return jsonEncode(records);
  }

  Future<void> uploadDimensionJson(String dimensionId, {String bucket = 'dashboard'}) async {
    final jsonString = await generateDimensionJson(dimensionId);
    final bytes = Uint8List.fromList(utf8.encode(jsonString));
    final path = '$empresaId/dimension_$dimensionId.json';
    await _client.storage
        .from(bucket)
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'application/json',
            upsert: true,
          ),
        );
  }

  // BLINDAJE: método utilitario para forzar Map<String, Map<String, double>>
  static Map<String, Map<String, double>> blindarSistemasPorNivel(Map data) {
    final Map<String, Map<String, double>> result = {};
    data.forEach((sistema, niveles) {
      if (niveles is Map) {
        final Map<String, double> inner = {};
        niveles.forEach((nivel, valor) {
          if (valor is double) {
            inner[nivel.toString()] = valor;
          } else if (valor is num) {
            inner[nivel.toString()] = valor.toDouble();
          } else {
            inner[nivel.toString()] = double.tryParse(valor.toString()) ?? 0.0;
          }
        });
        result[sistema.toString()] = inner;
      }
    });
    return result;
  }

  Future<void> _fetchAndNotify(DashboardListener onUpdate) async {
    final datos = await _client
        .from('calificaciones')
        .select('id_asociado, id_dimension, puntaje, sistemas, cargo_raw')
        .eq('id_empresa', empresaId);

    // Map para sumar puntajes por sistema‐nivel
    final Map<String, Map<String, double>> sistemasSum = {};
    // Map para contar cuántas evaluaciones por sistema‐nivel
    final Map<String, Map<String, int>> sistemasCount = {};

    for (final rec in datos as List) {
      final puntaje = (rec['puntaje'] as num?)?.toDouble() ?? 0.0;
      // Determina nivel según cargo_raw (ejecutivo/gerente/miembro)
      final cargo = (rec['cargo_raw'] as String?)?.toLowerCase() ?? '';
      String? nivel;
      if (cargo.contains('ejecutivo')) {
        nivel = 'E';
      } else if (cargo.contains('gerente')) nivel = 'G';
      else if (cargo.contains('miembro')) nivel = 'M';
      if (nivel == null) continue;

      final sistemasRaw = (rec['sistemas'] as List?)?.cast<String>() ?? [];
      for (final sis in sistemasRaw) {
        final sistema = sis.trim();
        // Inicializa sumas y contadores
        sistemasSum.putIfAbsent(sistema, () => {'E':0, 'G':0, 'M':0});
        sistemasCount.putIfAbsent(sistema, () => {'E':0, 'G':0, 'M':0});
        // Acumula y cuenta
        sistemasSum[sistema]![nivel] = sistemasSum[sistema]![nivel]! + puntaje;
        sistemasCount[sistema]![nivel] = sistemasCount[sistema]![nivel]! + 1;
      }
    }

    // Calcula promedios por sistema‐nivel
    final Map<String, Map<String, double>> sistemasPromedio = {};
    sistemasSum.forEach((sistema, sumMap) {
      final cntMap = sistemasCount[sistema]!;
      sistemasPromedio[sistema] = {
        'E': cntMap['E']! > 0 ? sumMap['E']! / cntMap['E']! : 0.0,
        'G': cntMap['G']! > 0 ? sumMap['G']! / cntMap['G']! : 0.0,
        'M': cntMap['M']! > 0 ? sumMap['M']! / cntMap['M']! : 0.0,
      };
    });

    // Notifica usando el mapa de promedios, no de conteos
    onUpdate(DashboardMetrics(
      promedioPorDimension: {},
      conteoPorDimension: {},
      sistemasPorNivel: sistemasPromedio,
      principiosPorNivel: {}, 
      comportamientosPorNivel: {},
    ));

    // Auto subir JSON por cada dimensión
    for (final dim in sistemasPromedio.keys) {
      await uploadDimensionJson(dim);
    }
  }
}
