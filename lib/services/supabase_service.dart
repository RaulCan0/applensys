// ignore_for_file: unused_element

import 'dart:io';
import 'dart:typed_data';

import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:applensys/models/level_averages.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Añadir importación
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // AUTH
  Future<Map<String, dynamic>> register(String email, String password, String telefono) async {
    try {
      await _client.auth.signUp(email: email, password: password, data: {'telefono': telefono});
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception("Usuario no autenticado");

    final archivo = File(rutaLocal);
    final fileName = archivo.uri.pathSegments.last;
    final storagePath = '$userId/$fileName';

    await _client.storage
        .from('perfil')
        .upload(
          storagePath,
          archivo,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('perfil').getPublicUrl(storagePath);

    // Guarda la URL en la tabla usuarios
    await _client.from('usuarios').update({'foto_url': publicUrl}).eq('id', userId);

    return publicUrl;
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

  Future<List<LevelAverages>> getDimensionAverages(String evaluacionId) async {
    final response = await _client
        .from('promedios_comportamientos')
        .select('dimension, nivel, valor')
        .eq('evaluacion_id', evaluacionId);

    final Map<String, Map<String, List<double>>> tempAverages = {};

    for (final row in response) {
      final dimension = row['dimension'] as String;
      final nivel = row['nivel'] as String;
      final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;

      tempAverages.putIfAbsent(dimension, () => {});
      tempAverages[dimension]!.putIfAbsent(nivel, () => []);
      tempAverages[dimension]![nivel]!.add(valor);
    }

    final List<LevelAverages> result = [];
    int idCounter = 0;

    tempAverages.forEach((dimensionName, niveles) {
      double sumEjecutivo = 0;
      int countEjecutivo = 0;
      double sumGerente = 0;
      int countGerente = 0;
      double sumMiembro = 0;
      int countMiembro = 0;

      for (var v in (niveles['Ejecutivo'] ?? [])) {
        sumEjecutivo += v;
        countEjecutivo++;
      }
      for (var v in (niveles['Gerente'] ?? [])) {
        sumGerente += v;
        countGerente++;
      }
      for (var v in (niveles['Miembro'] ?? [])) {
        sumMiembro += v;
        countMiembro++;
      }

      final avgEjecutivo = countEjecutivo > 0 ? sumEjecutivo / countEjecutivo : 0.0;
      final avgGerente = countGerente > 0 ? sumGerente / countGerente : 0.0;
      final avgMiembro = countMiembro > 0 ? sumMiembro / countMiembro : 0.0;
      final avgGeneral = (avgEjecutivo + avgGerente + avgMiembro) / 3;

      int dimensionIdNumeric = int.tryParse(dimensionName.replaceAll(RegExp(r'[^0-9]'), '')) ?? idCounter;

      result.add(LevelAverages(
        id: idCounter++,
        nombre: dimensionName,
        ejecutivo: double.parse(avgEjecutivo.toStringAsFixed(2)),
        gerente: double.parse(avgGerente.toStringAsFixed(2)),
        miembro: double.parse(avgMiembro.toStringAsFixed(2)),
        dimensionId: dimensionIdNumeric,
        general: double.parse(avgGeneral.toStringAsFixed(2)),
        nivel: '',
      ));
    });
    return result;
  }

  Future<List<LevelAverages>> getLevelLineData(String evaluacionId) async {
    final response = await _client
        .from('promedios_comportamientos')
        .select('nivel, valor')
        .eq('evaluacion_id', evaluacionId);

    final Map<String, List<double>> tempAverages = {};

    for (final row in response) {
      final nivel = row['nivel'] as String;
      final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;
      tempAverages.putIfAbsent(nivel, () => []);
      tempAverages[nivel]!.add(valor);
    }

    final List<LevelAverages> result = [];
    int idCounter = 0;

    tempAverages.forEach((nivelName, valores) {
      double sum = valores.fold(0.0, (prev, el) => prev + el);
      double avg = valores.isNotEmpty ? sum / valores.length : 0.0;

      double ejecutivo = 0.0, gerente = 0.0, miembro = 0.0;
      if (nivelName.toLowerCase() == 'ejecutivo') ejecutivo = avg;
      if (nivelName.toLowerCase() == 'gerente') gerente = avg;
      if (nivelName.toLowerCase() == 'miembro') miembro = avg;

      result.add(LevelAverages(
        id: idCounter++,
        nombre: nivelName,
        ejecutivo: double.parse(ejecutivo.toStringAsFixed(2)),
        gerente: double.parse(gerente.toStringAsFixed(2)),
        miembro: double.parse(miembro.toStringAsFixed(2)),
        dimensionId: 0,
        general: double.parse(avg.toStringAsFixed(2)),
        nivel: nivelName,
      ));
    });
    return result;
  }

  Future<List<LevelAverages>> getPrinciplesAverages(String evaluacionId) async {
    final response = await _client
        .from('promedios_comportamientos')
        .select('principio, nivel, valor')
        .eq('evaluacion_id', evaluacionId);

    final Map<String, Map<String, List<double>>> tempAverages = {}; // principio -> (nivel -> [valores])

    for (final row in response) {
      final principio = row['principio'] as String;
      final nivel = row['nivel'] as String;
      final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;

      tempAverages.putIfAbsent(principio, () => {});
      tempAverages[principio]!.putIfAbsent(nivel, () => []);
      tempAverages[principio]![nivel]!.add(valor);
    }

    final List<LevelAverages> result = [];
    int idCounter = 0;

    tempAverages.forEach((principioName, niveles) {
      double sumEjecutivo = 0, sumGerente = 0, sumMiembro = 0;
      int countEjecutivo = 0, countGerente = 0, countMiembro = 0;

      for (var v in (niveles['Ejecutivo'] ?? [])) { sumEjecutivo += v; countEjecutivo++; }
      for (var v in (niveles['Gerente'] ?? [])) { sumGerente += v; countGerente++; }
      for (var v in (niveles['Miembro'] ?? [])) { sumMiembro += v; countMiembro++; }

      final avgEjecutivo = countEjecutivo > 0 ? sumEjecutivo / countEjecutivo : 0.0;
      final avgGerente = countGerente > 0 ? sumGerente / countGerente : 0.0;
      final avgMiembro = countMiembro > 0 ? sumMiembro / countMiembro : 0.0;
      final avgGeneral = (avgEjecutivo + avgGerente + avgMiembro) / 3;
      
      // Asumimos que los principios no tienen un ID numérico fácilmente extraíble del nombre.
      // Usamos el contador para el ID del LevelAverage.
      // El dimensionId no es directamente aplicable aquí.
      result.add(LevelAverages(
        id: idCounter++,
        nombre: principioName,
        ejecutivo: double.parse(avgEjecutivo.toStringAsFixed(2)),
        gerente: double.parse(avgGerente.toStringAsFixed(2)),
        miembro: double.parse(avgMiembro.toStringAsFixed(2)),
        dimensionId: 0, // No es específico de una dimensión en este contexto de resumen
        general: double.parse(avgGeneral.toStringAsFixed(2)),
        nivel: '',
      ));
    });
    return result;
  }

  Future<List<LevelAverages>> getBehaviorAverages(String evaluacionId) async {
    final response = await _client
        .from('promedios_comportamientos')
        .select('comportamiento, nivel, valor')
        .eq('evaluacion_id', evaluacionId);

    final Map<String, Map<String, List<double>>> tempAverages = {}; // comportamiento -> (nivel -> [valores])

    for (final row in response) {
      final comportamiento = row['comportamiento'] as String;
      final nivel = row['nivel'] as String;
      final valor = (row['valor'] as num?)?.toDouble() ?? 0.0;

      tempAverages.putIfAbsent(comportamiento, () => {});
      tempAverages[comportamiento]!.putIfAbsent(nivel, () => []);
      tempAverages[comportamiento]![nivel]!.add(valor);
    }

    final List<LevelAverages> result = [];
    int idCounter = 0;

    tempAverages.forEach((comportamientoName, niveles) {
      double sumEjecutivo = 0, sumGerente = 0, sumMiembro = 0;
      int countEjecutivo = 0, countGerente = 0, countMiembro = 0;

      for (var v in (niveles['Ejecutivo'] ?? [])) { sumEjecutivo += v; countEjecutivo++; }
      for (var v in (niveles['Gerente'] ?? [])) { sumGerente += v; countGerente++; }
      for (var v in (niveles['Miembro'] ?? [])) { sumMiembro += v; countMiembro++; }

      final avgEjecutivo = countEjecutivo > 0 ? sumEjecutivo / countEjecutivo : 0.0;
      final avgGerente = countGerente > 0 ? sumGerente / countGerente : 0.0;
      final avgMiembro = countMiembro > 0 ? sumMiembro / countMiembro : 0.0;
      final avgGeneral = (avgEjecutivo + avgGerente + avgMiembro) / 3;

      result.add(LevelAverages(
        id: idCounter++,
        nombre: comportamientoName,
        ejecutivo: double.parse(avgEjecutivo.toStringAsFixed(2)),
        gerente: double.parse(avgGerente.toStringAsFixed(2)),
        miembro: double.parse(avgMiembro.toStringAsFixed(2)),
        dimensionId: 0, // No es específico de una dimensión en este contexto de resumen
        general: double.parse(avgGeneral.toStringAsFixed(2)),
        nivel: '',
      ));
    });
    return result;
  }

  Future<List<LevelAverages>> getSystemAverages(String evaluacionId) async {
    final response = await _client
        .from('promedios_sistemas')
        .select('sistema, nivel, conteo')
        .eq('evaluacion_id', evaluacionId);

    final Map<String, Map<String, int>> tempCounts = {}; // sistema -> (nivel -> conteo_total)

    for (final row in response) {
      final sistema = row['sistema'] as String;
      final nivel = row['nivel'] as String;
      final conteo = (row['conteo'] as num?)?.toInt() ?? 0;

      tempCounts.putIfAbsent(sistema, () => {});
      tempCounts[sistema]!.update(nivel, (existing) => existing + conteo, ifAbsent: () => conteo);
    }

    final List<LevelAverages> result = [];
    int idCounter = 0;

    tempCounts.forEach((sistemaName, niveles) {
      final conteoEjecutivo = (niveles['Ejecutivo'] ?? 0).toDouble();
      final conteoGerente = (niveles['Gerente'] ?? 0).toDouble();
      final conteoMiembro = (niveles['Miembro'] ?? 0).toDouble();
      
      // Para sistemas, 'general' podría ser la suma de conteos o un promedio de ellos.
      // Usaremos la suma de los conteos como valor "general" para representar la actividad total del sistema.
      // O, si se prefiere un promedio, podría ser (conteoEjecutivo + conteoGerente + conteoMiembro) / 3.
      // Por coherencia con los otros gráficos que muestran promedios, un promedio de los conteos podría ser más adecuado
      // si estos valores se van a comparar o mostrar de manera similar.
      // Sin embargo, dado que son conteos, la suma podría ser más intuitiva.
      // Optaré por un promedio de los conteos para mantener la escala si se grafican juntos.
      final generalValue = (conteoEjecutivo + conteoGerente + conteoMiembro) / 3;


      result.add(LevelAverages(
        id: idCounter++,
        nombre: sistemaName,
        ejecutivo: conteoEjecutivo,
        gerente: conteoGerente,
        miembro: conteoMiembro,
        dimensionId: 0, 
        general: double.parse(generalValue.toStringAsFixed(2)),
        nivel: '',
      ));
    });
    return result;
  }

  Future<double> obtenerProgresoAsociado({
    required String evaluacionId,
    required String asociadoId,
    required String dimensionId,
  }) async {
    final response = await _client
        .from('calificaciones')
        .select('comportamiento')
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', evaluacionId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

    final total = response.length;
    final mapaTotales = {'1': 6, '2': 14, '3': 8};
    final totalDimension = mapaTotales[dimensionId] ?? 1;
    return total / totalDimension;
  }

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
      return 0.0; // Return 0.0 in case of an error
    }
  }

  Future<void> guardarEvaluacionDraft(String evaluacionId) async {
    await _client
        .from('evaluaciones')
        .update({'finalizada': false})
        .eq('id', evaluacionId);
  }

  Future<void> finalizarEvaluacion(String evaluacionId) async {
    // 1. Marcar la evaluación como finalizada en la tabla correcta
    await _client
        .from('evaluaciones')
        .update({'finalizada': true})
        .eq('id', evaluacionId);

    // 2. Acceder a los datos cacheados localmente
    final Map<String, Map<String, List<Map<String, dynamic>>>> todasLasTablas = TablasDimensionScreen.tablaDatos;

    if (todasLasTablas.isNotEmpty) {
      // 3. Iterar sobre cada dimensión en los datos cacheados
      for (var dimensionEntry in todasLasTablas.entries) {
        String dimensionName = dimensionEntry.key;
        Map<String, List<Map<String, dynamic>>> datosPorEvaluacionParaDimension = dimensionEntry.value;

        // Verificar si hay datos para el evaluacionId actual en esta dimensión
        if (datosPorEvaluacionParaDimension.containsKey(evaluacionId)) {
          List<Map<String, dynamic>>? filasParaSubir = datosPorEvaluacionParaDimension[evaluacionId];

          if (filasParaSubir != null && filasParaSubir.isNotEmpty) {
            await subirPromediosCompletos(
              evaluacionId: evaluacionId,
              dimension: dimensionName,
              filas: filasParaSubir,
            );
            ('Promedios subidos para evaluacionId: $evaluacionId, dimension: $dimensionName');
          } else {
            ('No hay filas para subir para evaluacionId: $evaluacionId, dimension: $dimensionName');
          }
        } else {
          ('No hay datos para evaluacionId: $evaluacionId en la dimensión: $dimensionName');
        }
      }
    } else {
      ('No hay datos cacheados en TablasDimensionScreen.tablaDatos para procesar.');
    }

    // 4. Limpiar todos los datos cacheados localmente
    ('Limpiando todos los datos cacheados localmente...');
    TablasDimensionScreen.tablaDatos.clear(); // Limpiar la variable estática

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tabla_datos'); // Limpiar SharedPreferences

    ('Todos los datos cacheados localmente han sido eliminados.');
  }

  Future<double> calcularProgresoDimensionGlobal(String empresaId, String dimensionId) async {
    try {
      final response = await _client
          .from('calificaciones')
          .select('comportamiento')
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? -1);

      final evaluados = (response as List).map((e) => e['comportamiento'].toString()).toSet().length;

      const mapaTotales = {'1': 6, '2': 14, '3': 8};
      final totalDimension = mapaTotales[dimensionId] ?? 1;

      return evaluados / totalDimension;
    } catch (e) {
      return 0.0;
    }
  }

  Future<void> insertarPromediosDashboard({
    required String evaluacionId,
    required String dimension,
    required Map<String, double> promedios,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    final data = promedios.entries.map((entry) => {
      'id': uuid.v4(),
      'evaluacion_id': evaluacionId,
      'dimension': dimension,
      'nivel': entry.key,
      'promedio': entry.value,
      'created_at': now,
    }).toList();

    await _client.from('resultados_dashboard').insert(data);
  }

  Future<void> insertarPromediosSistemas({
    required String evaluacionId,
    required String dimension,
    required Map<String, int> conteos,
  }) async {
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    final data = conteos.entries.map((entry) => {
      'id': uuid.v4(),
      'evaluacion_id': evaluacionId,
      'dimension': dimension,
      'nivel': entry.key,
      'conteo_sistemas': entry.value,
      'created_at': now,
    }).toList();

    await _client.from('promedios_sistemas').insert(data);
  }

  Future<void> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    final response = await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
  }

  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    final res = _client.storage.from(bucket).getPublicUrl(path);
    if (res.isEmpty) {
      throw Exception('Failed to generate public URL for the file.');
    }
    return res;
  }
}