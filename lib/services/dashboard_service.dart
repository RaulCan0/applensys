import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo de métricas del dashboard
class DashboardMetrics {
  final Map<String, double> promedioPorDimension;
  final Map<String, int> conteoPorDimension;

  DashboardMetrics({
    required this.promedioPorDimension,
    required this.conteoPorDimension, required Map principiosPorNivel, required Map comportamientosPorNivel, required Map sistemasPorNivel,
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
    final records = await _client
        .from('calificaciones')
        .select()
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

  Future<void> _fetchAndNotify(DashboardListener onUpdate) async {
    // Obtiene todas las calificaciones de la empresa
    final datos = await _client
        .from('calificaciones')
        .select('id_dimension, puntaje')
        .eq('id_empresa', empresaId);

    // Agrupa puntajes por dimensión
    final Map<String, List<double>> agrupados = {};
    for (final rec in datos as List) {
      final dim = rec['id_dimension']?.toString() ?? '0';
      final puntaje = (rec['puntaje'] as num?)?.toDouble() ?? 0.0;
      agrupados.putIfAbsent(dim, () => []).add(puntaje);
    }

    // Calcula promedios y conteos
    final Map<String, double> promedios = {};
    final Map<String, int> conteos = {};
    agrupados.forEach((dim, lista) {
      final count = lista.length;
      final avg = count > 0 ? lista.reduce((a, b) => a + b) / count : 0.0;
      promedios[dim] = avg;
      conteos[dim] = count;
    });

    // Notifica al listener
    onUpdate(DashboardMetrics(
      promedioPorDimension: promedios,
      conteoPorDimension: conteos, principiosPorNivel: {}, comportamientosPorNivel: {}, sistemasPorNivel: {},
    ));

    // Auto subir JSON por cada dimensión
    for (final dim in promedios.keys) {
      await uploadDimensionJson(dim);
    }
  }
}
