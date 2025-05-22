import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestión de evaluaciones
class EvaluacionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Evaluacion>> getEvaluaciones() async {
    final res = await _client.from('detalles_evaluacion').select();
    return (res as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  Future<Evaluacion> addEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id.isEmpty ||
        evaluacion.empresaId.isEmpty ||
        evaluacion.asociadoId.isEmpty) {
      throw Exception('Todos los IDs son obligatorios');
    }
    final data = await _client
        .from('detalles_evaluacion')
        .insert(evaluacion.toMap())
        .select()
        .single();
    return Evaluacion.fromMap(data);
  }

  Future<void> updateEvaluacion(String id, Evaluacion evaluacion) async {
    await _client.from('detalles_evaluacion').update(evaluacion.toMap()).eq('id', id);
  }

  Future<void> deleteEvaluacion(String id) async {
    await _client.from('detalles_evaluacion').delete().eq('id', id);
  }

  Future<Evaluacion?> buscarEvaluacionExistente(String empresaId, String asociadoId) async {
    final res = await _client
        .from('evaluaciones')
        .select()
        .eq('empresa_id', empresaId)
        .eq('asociado_id', asociadoId)
        .maybeSingle();
    if (res == null) return null;
    return Evaluacion.fromMap(res);
  }

  Future<Evaluacion> crearEvaluacionSiNoExiste(String empresaId, String asociadoId) async {
    final existente = await buscarEvaluacionExistente(empresaId, asociadoId);
    if (existente != null) return existente;
    final nueva = Evaluacion(
      id: const Uuid().v4(),
      empresaId: empresaId,
      asociadoId: asociadoId,
      fecha: DateTime.now(),
    );
    await _client.from('evaluaciones').insert(nueva.toMap());
    return nueva;
  }

  Future<void> guardarEvaluacionDraft(String evaluacionId) async {
    await _client.from('evaluaciones').update({'finalizada': false}).eq('id', evaluacionId);
  }

  Future<void> finalizarEvaluacion(String evaluacionId) async {
    await _client.from('detalles_evaluacion').update({'finalizada': true}).eq('id', evaluacionId);
  }

  /// Obtiene el progreso de la dimensión para una empresa
  Future<double> obtenerProgresoDimension(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('comportamiento')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

      final total = (response as List).length;
      const mapaTotales = {'1': 6, '2': 14, '3': 8};
      final totalDimension = mapaTotales[dimensionId] ?? 1;

      return total / totalDimension;
    } catch (e) {
      return 0.0;
    }
  }

  // Métodos de calificaciones fusionados desde calificacion_service.dart

  Future<void> addCalificacion(Calificacion calificacion) async {
    await _client.from('calificaciones').insert(calificacion.toMap());
  }

  Future<void> updateCalificacion(String id, int puntaje) async {
    await _client.from('calificaciones').update({'puntaje': puntaje}).eq('id', id);
  }

  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    await _client.from('calificaciones').update(calificacion.toMap()).eq('id', calificacion.id);
  }

  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    final res = await _client.from('calificaciones').select().eq('id_asociado', idAsociado);
    return (res as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  Future<Calificacion?> getCalificacionExistente({
    required String idAsociado,
    required String idEmpresa,
    required int idDimension,
    required String comportamiento,
  }) async {
    final res = await _client
        .from('calificaciones')
        .select()
        .eq('id_asociado', idAsociado)
        .eq('id_empresa', idEmpresa)
        .eq('id_dimension', idDimension)
        .eq('comportamiento', comportamiento)
        .maybeSingle();
    if (res == null) return null;
    return Calificacion.fromMap(res);
  }
}
