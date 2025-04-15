import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empresa.dart';
import '../models/asociado.dart';
import '../models/evaluacion.dart';
import '../models/calificacion.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // =============== EMPRESAS ===============
  Future<List<Empresa>> getEmpresas() async {
    final response = await _client.from('empresas').select();
    return (response as List).map((e) => Empresa.fromMap(e)).toList();
  }

  Future<void> addEmpresa(Empresa empresa) async {
    await _client.from('empresas').insert(empresa.toMap());
  }

  Future<void> updateEmpresa(String id, Empresa empresa) async {
    await _client.from('empresas').update(empresa.toMap()).eq('id', id);
  }

  Future<void> deleteEmpresa(String id) async {
    await _client.from('empresas').delete().eq('id', id);
  }

  // =============== ASOCIADOS ===============
  Future<List<Asociado>> getAsociadosPorEmpresa(String empresaId) async {
    final response = await _client
        .from('asociados')
        .select()
        .eq('empresa_id', empresaId);
    return (response as List).map((e) => Asociado.fromMap(e)).toList();
  }

  Future<void> addAsociado(Asociado asociado) async {
    await _client.from('asociados').insert(asociado.toMap());
  }

  Future<void> updateAsociado(String id, Asociado asociado) async {
    await _client.from('asociados').update(asociado.toMap()).eq('id', id);
  }

  Future<void> deleteAsociado(String id) async {
    await _client.from('asociados').delete().eq('id', id);
  }

  // =============== EVALUACIONES ===============
  Future<List<Evaluacion>> getEvaluaciones() async {
    final response = await _client.from('detalles_evaluacion').select();
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  Future<Evaluacion> addEvaluacion(Evaluacion evaluacion) async {
    final data =
        await _client
            .from('detalles_evaluacion')
            .insert(evaluacion.toMap())
            .select()
            .single();
    return Evaluacion.fromMap(data);
  }

  Future<void> updateEvaluacion(String id, Evaluacion evaluacion) async {
    await _client
        .from('detalles_evaluacion')
        .update(evaluacion.toMap())
        .eq('id', id);
  }

  Future<void> deleteEvaluacion(String id) async {
    await _client.from('detalles_evaluacion').delete().eq('id', id);
  }

  // =============== CALIFICACIONES ===============
  Future<List<Calificacion>> getCalificacionesPorAsociado(
    String idAsociado,
  ) async {
    final response = await _client
        .from('calificaciones')
        .select()
        .eq('id_asociado', idAsociado);
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  Future<void> addCalificacion(Calificacion calificacion) async {
    await _client.from('calificaciones').insert(calificacion.toMap());
  }

  Future<void> updateCalificacion(String id, int nuevoPuntaje) async {
    await _client
        .from('calificaciones')
        .update({'puntaje': nuevoPuntaje})
        .eq('id', id);
  }

  Future<void> deleteCalificacion(String id) async {
    await _client.from('calificaciones').delete().eq('id', id);
  }

  Future<List<Calificacion>> getAllCalificaciones() async {
    final response = await _client.from('calificaciones').select();
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  from(String s) {}
}
