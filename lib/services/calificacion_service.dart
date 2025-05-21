import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/models/calificacion.dart';

/// Servicio para gestión de calificaciones
class CalificacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Inserta una nueva calificación
  Future<void> addCalificacion(Calificacion calificacion) async {
    await _client.from('calificaciones').insert(calificacion.toMap());
  }

  /// Actualiza el puntaje de una calificación existente
  Future<void> updateCalificacion(String id, int puntaje) async {
    await _client.from('calificaciones').update({'puntaje': puntaje}).eq('id', id);
  }

  /// Actualiza todos los campos de una calificación existente
  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    await _client
        .from('calificaciones')
        .update(calificacion.toMap())
        .eq('id', calificacion.id);
  }

  /// Elimina una calificación
  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  /// Obtiene todas las calificaciones de un asociado
  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    final res = await _client.from('calificaciones').select().eq('id_asociado', idAsociado);
    return (res as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  /// Obtiene una calificación específica por campos de filtro
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
