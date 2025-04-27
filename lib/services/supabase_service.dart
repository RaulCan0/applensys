import 'dart:io';

import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // AUTH
  Future<Map<String, dynamic>> register(String email, String password) async {
    try {
      await _client.auth.signUp(email: email, password: password);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  String? get userId => _client.auth.currentUser?.id;

  // EMPRESAS
  Future<List<Empresa>> getEmpresas() async {
    try {
      final response = await _client.from('empresas').select();
      return response.map((e) => Empresa.fromMap(e)).toList();
    } catch (e) {
      return [];
    }
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

  // ASOCIADOS
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

  // EVALUACIONES
  Future<List<Evaluacion>> getEvaluaciones() async {
    final response = await _client.from('detalles_evaluacion').select();
    return (response as List).map((e) => Evaluacion.fromMap(e)).toList();
  }

  Future<Evaluacion> addEvaluacion(Evaluacion evaluacion) async {
    if (evaluacion.id.isEmpty ||
        evaluacion.empresaId.isEmpty ||
        evaluacion.asociadoId.isEmpty) {
      throw Exception('Todos los IDs son obligatorios');
    }

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

  // CALIFICACIONES
  Future<List<Calificacion>> getCalificacionesPorAsociado(
    String idAsociado,
  ) async {
    final response = await _client
        .from('calificaciones')
        .select()
        .eq('id_asociado', idAsociado);
    return (response as List).map((e) => Calificacion.fromMap(e)).toList();
  }

  Future<void> addCalificacion(Calificacion calificacion, {required String id, required String idAsociado}) async {
    try {
      // Verificación más detallada
      if (calificacion.id.isEmpty) {
        throw Exception("ID de calificación vacío");
      }
      if (calificacion.idAsociado.isEmpty) {
        throw Exception("ID de asociado vacío");
      }
      if (calificacion.idEmpresa.isEmpty) {
        throw Exception("ID de empresa vacío");
      }
      if (calificacion.idDimension == 0) {
        throw Exception("ID de dimensión vacío");
      }

      ("Intentando guardar calificación:");
      ("ID: ${calificacion.id}");
      ("ID Asociado: ${calificacion.idAsociado}");
      ("ID Empresa: ${calificacion.idEmpresa}");
      ("ID Dimensión: ${calificacion.idDimension}");

      // Si todo está correcto, intentar guardar
      await _client.from('calificaciones').insert(calificacion.toMap());
      ("✅ Calificación guardada con éxito");
    } catch (e) {
      ("❌ Error al guardar calificación: $e");
      rethrow; // Re-lanzar para manejar arriba
    }
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

  // DASHBOARD
  Future<List<Map<String, dynamic>>> getResultadosDashboard({
    String? empresaId,
    int? dimensionId,
  }) async {
    final query = _client.from('resultados_dashboard').select();
    if (empresaId != null) query.eq('empresa_id', empresaId);
    if (dimensionId != null) query.eq('dimension', dimensionId);

    final response = await query;
    return (response as List).map((e) {
      return {
        'titulo': e['dimension'] ?? 'Sin título',
        'promedio': e['promedio_general'] ?? 0.0,
      };
    }).toList();
  }

  Future<void> subirResultadosDashboard(
    List<Map<String, dynamic>> resultados,
  ) async {
    if (resultados.isEmpty) return;

    final inserciones =
        resultados.map((resultado) {
          return {
            'id': const Uuid().v4(),
            'dimension': resultado['dimension'],
            'promedio_ejecutivo': resultado['promedio_ejecutivo'],
            'promedio_gerente': resultado['promedio_gerente'],
            'promedio_miembro': resultado['promedio_miembro'],
            'promedio_general': resultado['promedio_general'],
            'fecha': resultado['fecha'],
            'empresa_id': resultado['empresa_id'] ?? '',
          };
        }).toList();

    await _client.from('resultados_dashboard').insert(inserciones);
  }

  Future<void> subirDetallesComportamiento(
    List<Map<String, dynamic>> detalles,
  ) async {
    if (detalles.isEmpty) return;
    await _client.from('detalles_comportamiento').insert(detalles);
  }

  // PERFIL
  Future<Map<String, dynamic>?> getPerfil() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final response =
        await _client.from('usuarios').select().eq('id', user.id).single();
    return response;
  }

  Future<void> actualizarPerfil(Map<String, dynamic> valores) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("Usuario no autenticado");

    await _client.from('usuarios').update(valores).eq('id', userId);
  }

  Future<String> subirFotoPerfil(String rutaLocal) async {
    final archivo = File(rutaLocal);
    final storagePath = 'fotos_perfil/\$userId/\$nombre';

    await _client.storage
        .from('perfil')
        .upload(
          storagePath,
          archivo,
          fileOptions: const FileOptions(upsert: true),
        );

    return _client.storage.from('perfil').getPublicUrl(storagePath);
  }
   // NUEVO: Buscar evaluacion existente
  Future<Evaluacion?> buscarEvaluacionExistente(String empresaId, String asociadoId) async {
    final response = await _client
        .from('evaluaciones')
        .select()
        .eq('empresa_id', empresaId)
        .eq('asociado_id', asociadoId)
        .maybeSingle();

    if (response == null) return null;
    return Evaluacion.fromMap(response);
  }

  // NUEVO: Crear evaluacion si no existe
  Future<Evaluacion> crearEvaluacionSiNoExiste(String empresaId, String asociadoId) async {
    final existente = await buscarEvaluacionExistente(empresaId, asociadoId);
    if (existente != null) return existente;

    final nuevaEvaluacion = Evaluacion(
      id: const Uuid().v4(),
      empresaId: empresaId,
      asociadoId: asociadoId,
      fecha: DateTime.now(),
    );
    await _client.from('evaluaciones').insert(nuevaEvaluacion.toMap());
    return nuevaEvaluacion;
  }
}
