import 'dart:io';

import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:applensys/models/level_averages.dart';
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

Future<void> insertar(String tabla, Map<String, dynamic> valores) async {
    await _client.from(tabla).insert(valores);
  }

  Future<void> subirPromediosCompletos({
    required String evaluacionId,
    required String dimension,
    required List<Map<String, dynamic>> filas,
  }) async {
    final sumas = <String, Map<String, Map<String, int>>>{};
    final conteos = <String, Map<String, Map<String, int>>>{};
    final sistemasPorNivel = <String, Map<String, Map<String, int>>>{};

    for (var f in filas) {
      final principio = f['principio'] as String;
      final comportamiento = f['comportamiento'] as String;
      final nivel = (f['cargo'] as String).trim();
      final valor = f['valor'] as int;
      final sistemas = (f['sistemas'] as List<dynamic>?)?.cast<String>() ?? [];

      sumas.putIfAbsent(principio, () => {});
      sumas[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});
      conteos.putIfAbsent(principio, () => {});
      conteos[principio]!.putIfAbsent(comportamiento, () => {'Ejecutivo': 0, 'Gerente': 0, 'Miembro': 0});

      sumas[principio]![comportamiento]![nivel] =
        sumas[principio]![comportamiento]![nivel]! + valor;
      conteos[principio]![comportamiento]![nivel] =
        (conteos[principio]![comportamiento]![nivel] ?? 0) + 1;

      for (final sistema in sistemas) {
        sistemasPorNivel.putIfAbsent(sistema, () => {
          'Ejecutivo': {},
          'Gerente': {},
          'Miembro': {},
        });
        sistemasPorNivel[sistema]![nivel]![dimension] =
          (sistemasPorNivel[sistema]![nivel]![dimension] ?? 0) + 1;
      }
    }

    for (final p in sumas.keys) {
      for (final c in sumas[p]!.keys) {
        for (final nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
          final suma = sumas[p]![c]![nivel]!;
          final count = conteos[p]![c]![nivel]!;
          final promedio = count == 0 ? 0 : suma / count;
          await insertar('promedios_comportamientos', {
            'evaluacion_id': evaluacionId,
            'dimension': dimension,
            'principio': p,
            'comportamiento': c,
            'nivel': nivel,
            'valor': double.parse(promedio.toStringAsFixed(2)),
          });
        }
      }
    }

    for (final sistema in sistemasPorNivel.keys) {
      for (final nivel in ['Ejecutivo', 'Gerente', 'Miembro']) {
        final conteo = sistemasPorNivel[sistema]![nivel]?[dimension] ?? 0;
        await insertar('promedios_sistemas', {
          'evaluacion_id': evaluacionId,
          'dimension': dimension,
          'sistema': sistema,
          'nivel': nivel,
          'conteo': conteo,
        });
      }
    }
  }
  Future<List<LevelAverages>> getDimensionAverages(int empresaId) async {
  final res = await _client
      .from('detalle_evaluacion')
      .select('dimension_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
      .eq('empresa_id', empresaId);

  return (res as List).map((m) => LevelAverages(
        id: m['dimension_id'] as int,
        nombre: 'Dimensión ${m['dimension_id']}',
        ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
        gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
        miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
        dimensionId: m['dimension_id'] as int,
        general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                  ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                  ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3, nivel: '',
      )).toList();
}

Future<List<LevelAverages>> getLevelLineData(int empresaId) async {
  final res = await _client
      .from('detalle_evaluacion')
      .select('nivel, avg(calificacion) as promedio')
      .eq('empresa_id', empresaId);

  return (res as List).map((m) {
    final promedio = (m['promedio'] as num?)?.toDouble() ?? 0.0;
    return LevelAverages(
      id: nivelToId(m['nivel'] as String),
      nombre: m['nivel'] as String,
      ejecutivo: promedio,
      gerente: promedio,
      miembro: promedio,
      dimensionId: 0,
      general: promedio, nivel: '',
    );
  }).toList();
}

Future<List<LevelAverages>> getPrinciplesAverages(int empresaId) async {
  final res = await _client
      .from('detalle_evaluacion')
      .select('principio_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
      .eq('empresa_id', empresaId);

  return (res as List).map((m) => LevelAverages(
        id: m['principio_id'] as int,
        nombre: 'Principio ${m['principio_id']}',
        ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
        gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
        miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
        dimensionId: 0,
        general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                  ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                  ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3, nivel: '',
      )).toList();
}

Future<List<LevelAverages>> getBehaviorAverages(int empresaId) async {
  final res = await _client
      .from('detalle_evaluacion')
      .select('comportamiento_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
      .eq('empresa_id', empresaId);

  return (res as List).map((m) => LevelAverages(
        id: m['comportamiento_id'] as int,
        nombre: 'Comportamiento ${m['comportamiento_id']}',
        ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
        gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
        miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
        dimensionId: 0,
        general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                  ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                  ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3, nivel: '',
      )).toList();
}

Future<List<LevelAverages>> getSystemAverages(int empresaId) async {
  final res = await _client
      .from('detalle_sistema')
      .select('sistema_id, avg(ejecutivo) as ejecutivo, avg(gerente) as gerente, avg(miembro) as miembro')
      .eq('empresa_id', empresaId);

  return (res as List).map((m) => LevelAverages(
        id: m['sistema_id'] as int,
        nombre: 'Sistema ${m['sistema_id']}',
        ejecutivo: (m['ejecutivo'] as num?)?.toDouble() ?? 0.0,
        gerente: (m['gerente'] as num?)?.toDouble() ?? 0.0,
        miembro: (m['miembro'] as num?)?.toDouble() ?? 0.0,
        dimensionId: 0,
        general: (((m['ejecutivo'] as num?)?.toDouble() ?? 0.0) +
                  ((m['gerente'] as num?)?.toDouble() ?? 0.0) +
                  ((m['miembro'] as num?)?.toDouble() ?? 0.0)) / 3, nivel: '',
      )).toList();
}

int nivelToId(String nivel) {
  switch (nivel.toLowerCase()) {
    case 'ejecutivo':
      return 1;
    case 'gerente':
      return 2;
    case 'miembro':
      return 3;
    default:
      return 0;
  }
}

  // ...otros métodos y propiedades...

  Future<List<LevelAverages>> getLocalDimensionAverages() async {
    return [
      LevelAverages(id: 1, nombre: 'Liderazgo', ejecutivo: 4.1, gerente: 3.8, miembro: 4.0, dimensionId: 1, general: 4.0, nivel: ''),
      LevelAverages(id: 2, nombre: 'Gestión', ejecutivo: 3.9, gerente: 4.0, miembro: 4.1, dimensionId: 2, general: 4.0, nivel: ''),
      LevelAverages(id: 3, nombre: 'Tecnología', ejecutivo: 3.7, gerente: 3.9, miembro: 3.8, dimensionId: 3, general: 3.8, nivel: ''),
    ];
  }

  Future<List<LevelAverages>> getLocalLevelLineData() async {
    return [
      LevelAverages(id: 1, nombre: 'Ejecutivo', ejecutivo: 4.2, gerente: 0, miembro: 0, dimensionId: 0, general: 4.2, nivel: 'Ejecutivo'),
      LevelAverages(id: 2, nombre: 'Gerente', ejecutivo: 0, gerente: 3.9, miembro: 0, dimensionId: 0, general: 3.9, nivel: 'Gerente'),
      LevelAverages(id: 3, nombre: 'Miembro', ejecutivo: 0, gerente: 0, miembro: 4.0, dimensionId: 0, general: 4.0, nivel: 'Miembro'),
    ];
  }

  Future<List<LevelAverages>> getLocalPrinciplesAverages() async {
    return [
      LevelAverages(id: 1, nombre: 'Principio 1', ejecutivo: 4.0, gerente: 3.8, miembro: 4.1, dimensionId: 0, general: 4.0, nivel: ''),
      LevelAverages(id: 2, nombre: 'Principio 2', ejecutivo: 3.7, gerente: 3.9, miembro: 3.8, dimensionId: 0, general: 3.8, nivel: ''),
      LevelAverages(id: 3, nombre: 'Principio 3', ejecutivo: 4.2, gerente: 4.0, miembro: 4.1, dimensionId: 0, general: 4.1, nivel: ''),
    ];
  }

  Future<List<LevelAverages>> getLocalBehaviorAverages() async {
    return [
      LevelAverages(id: 1, nombre: 'Comportamiento 1', ejecutivo: 4.1, gerente: 3.8, miembro: 4.0, dimensionId: 0, general: 4.0, nivel: ''),
      LevelAverages(id: 2, nombre: 'Comportamiento 2', ejecutivo: 3.9, gerente: 4.0, miembro: 4.1, dimensionId: 0, general: 4.0, nivel: ''),
      LevelAverages(id: 3, nombre: 'Comportamiento 3', ejecutivo: 3.7, gerente: 3.9, miembro: 3.8, dimensionId: 0, general: 3.8, nivel: ''),
    ];
  }

  Future<List<LevelAverages>> getLocalSystemAverages() async {
    return [
      LevelAverages(id: 1, nombre: 'Sistema 1', ejecutivo: 4.0, gerente: 3.8, miembro: 4.1, dimensionId: 0, general: 4.0, nivel: ''),
      LevelAverages(id: 2, nombre: 'Sistema 2', ejecutivo: 3.7, gerente: 3.9, miembro: 3.8, dimensionId: 0, general: 3.8, nivel: ''),
      LevelAverages(id: 3, nombre: 'Sistema 3', ejecutivo: 4.2, gerente: 4.0, miembro: 4.1, dimensionId: 0, general: 4.1, nivel: ''),
    ];
  }
  Future<double> obtenerProgresoDimension(String evaluacionId, String dimensionId) async {
    try {
      final respuesta = await _client
          .from('detalle_evaluacion')
          .select('comportamiento_id')
          .eq('evaluacion_id', evaluacionId);

      final List<dynamic> registros = respuesta;
      final List<String> comportamientosEvaluados = registros
          .map((r) => r['comportamiento_id'].toString())
          .toSet()
          .toList();

      // Define qué comportamientos corresponden a cada dimensión
      final Map<String, List<String>> comportamientosPorDimension = {
        '1': [
          'Soporte', 'Reconocimiento', 'Comunidad',
          'Liderazgo de servidor', 'Valorar', 'Empoderamiento',
          'Mentalidad', 'Estructura', 'Reflexionar',
        ],
        '2': [
          'Análisis', 'Colaborar', 'Comprender',
          'Diseño', 'Atribución', 'A prueba de error',
          'Propiedad', 'Conectar', 'Ininterrumpido',
        ],
        '3': [
          'Demanda', 'Eliminar', 'Optimizar',
          'Impacto', 'Alinear', 'Aclarar',
          'Comunicar', 'Relación', 'Valor', 'Medida',
        ],
      };

      final List<String> comportamientosDimension = comportamientosPorDimension[dimensionId] ?? [];

      if (comportamientosDimension.isEmpty) return 0.0;

      final int total = comportamientosDimension.length;
      final int evaluados = comportamientosDimension
          .where((c) => comportamientosEvaluados.contains(c))
          .length;

      return evaluados / total;
    } catch (e) {
    ('Error al obtener progreso de dimensión: $e');
      return 0.0;
    }
  }
Future<void> guardarEvaluacionDraft(String evaluacionId) async {
  await _client
      .from('evaluaciones')
      .update({'finalizada': false})
      .eq('id', evaluacionId);
}

Future<void> finalizarEvaluacion(String evaluacionId) async {
  await _client
      .from('evaluaciones')
      .update({'finalizada': true})
      .eq('id', evaluacionId);
}
}
