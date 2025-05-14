import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data'; // Para manejar Uint8List
import '../models/empresa.dart';
import '../models/asociado.dart';
import '../models/evaluacion.dart';
import '../models/calificacion.dart';

class AppProvider with ChangeNotifier {
  final SupabaseClient _client = Supabase.instance.client;
  SharedPreferences? _prefs;

  List<Empresa> _empresas = [];
  List<Asociado> _asociados = [];
  final Map<String, dynamic> _cache = {};

  final Map<String, double> _progresoDimensiones = {};
  final Map<String, Map<String, double>> _progresoAsociados = {};
  final Map<String, List<Map<String, dynamic>>> _principios = {};
  final Map<String, Map<String, List<Map<String, dynamic>>>> _tablaDatos = {};

  List<Empresa> get empresas => _empresas;
  List<Asociado> get asociados => _asociados;
  Map<String, double> get progresoDimensiones => _progresoDimensiones;
  Map<String, Map<String, double>> get progresoAsociados => _progresoAsociados;
  Map<String, List<Map<String, dynamic>>> get principios => _principios;
  Map<String, Map<String, List<Map<String, dynamic>>>> get tablaDatos => _tablaDatos;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadEmpresas();
    notifyListeners();
  }

  Future<void> _loadEmpresas() async {
    try {
      final response = await _client.from('empresas').select();
      _empresas = (response as List).map((e) => Empresa.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error loading empresas: $e');
    }
  }

  Future<void> addEmpresa(Empresa empresa) async {
    try {
      await _client.from('empresas').insert(empresa.toMap());
      _empresas.add(empresa);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding empresa: $e');
    }
  }

  Future<void> deleteEmpresa(String id) async {
    try {
      await _client.from('empresas').delete().eq('id', id);
      _empresas.removeWhere((empresa) => empresa.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting empresa: $e');
    }
  }

  Future<void> syncData() async {
    try {
      debugPrint('Sincronizando datos...');
      await _loadEmpresas();
      for (var empresa in _empresas) {
        await loadAsociados(empresa.id);
        await loadProgresoDimensiones(empresa.id);
        await loadProgresoAsociados(empresa.id);
        await loadPrincipios(empresa.id);
        await loadTablaDatos(empresa.id);
      }
      debugPrint('Sincronización completada.');
    } catch (e) {
      debugPrint('Error durante la sincronización: $e');
    }
  }

  Future<void> clearCache() async {
    _cache.clear();
    await _prefs?.clear();
    notifyListeners();
  }

  // AUTH
  Future<bool> login(String email, String password) async {
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
    notifyListeners();
  }

  // ASOCIADOS
  Future<void> loadAsociados(String empresaId) async {
    try {
      final response = await _client.from('asociados').select().eq('empresa_id', empresaId);
      _asociados = (response as List).map((e) => Asociado.fromMap(e)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading asociados: $e');
    }
  }

  Future<void> addAsociado(Asociado asociado) async {
    try {
      await _client.from('asociados').insert(asociado.toMap());
      _asociados.add(asociado);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding asociado: $e');
    }
  }

  // PROMEDIOS
  Future<void> uploadPromedios(String evaluacionId, String dimension, List<Map<String, dynamic>> filas) async {
    if (filas.isEmpty) {
      debugPrint('No hay datos para subir en uploadPromedios.');
      return;
    }
    try {
      final data = filas.map((fila) => {
        'evaluacion_id': evaluacionId,
        'dimension': dimension,
        'nivel': fila['nivel'],
        'promedio': fila['promedio'],
        'created_at': DateTime.now().toIso8601String(),
      }).toList();
      await _client.from('promedios_comportamientos').insert(data);
      debugPrint('Promedios subidos exitosamente.');
    } catch (e) {
      debugPrint('Error subiendo promedios: $e');
    }
  }

  // BUCKETS
  Future<String> uploadFile(String bucket, String path, Uint8List bytes) async {
    try {
      final response = await _client.storage.from(bucket).uploadBinary(path, bytes);
      return _client.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file: $e');
      throw Exception('File upload failed');
    }
  }

  // PROGRESO
  Future<void> loadProgresoDimensiones(String empresaId) async {
    try {
      final response = await _client
          .from('progreso_dimensiones')
          .select()
          .eq('empresa_id', empresaId);
      for (var item in response) {
        _progresoDimensiones[item['dimension_id']] = item['progreso'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progreso dimensiones: $e');
    }
  }

  Future<void> loadProgresoAsociados(String empresaId) async {
    try {
      final response = await _client
          .from('progreso_asociados')
          .select()
          .eq('empresa_id', empresaId);
      for (var item in response) {
        final asociadoId = item['asociado_id'];
        _progresoAsociados[asociadoId] ??= {};
        _progresoAsociados[asociadoId]![item['dimension_id']] = item['progreso'];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading progreso asociados: $e');
    }
  }

  Future<void> loadPrincipios(String empresaId) async {
    try {
      final response = await _client
          .from('principios')
          .select()
          .eq('empresa_id', empresaId);
      for (var item in response) {
        final dimensionId = item['dimension_id'];
        _principios[dimensionId] ??= [];
        _principios[dimensionId]!.add(item);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading principios: $e');
    }
  }

  // TABLA DATOS
  Future<void> loadTablaDatos(String empresaId) async {
    try {
      final response = await _client
          .from('tabla_datos')
          .select()
          .eq('empresa_id', empresaId);

      for (var item in response) {
        final dimensionId = item['dimension_id'];
        final evaluacionId = item['evaluacion_id'];
        _tablaDatos[dimensionId] ??= {};
        _tablaDatos[dimensionId]![evaluacionId] ??= [];
        _tablaDatos[dimensionId]![evaluacionId]!.add(item);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar tablaDatos: $e');
    }
  }

  Future<void> clearTablaDatos() async {
    _tablaDatos.clear();
    notifyListeners();
  }

  void actualizarDato(
    String evaluacionId, {
    required String dimension,
    required String principio,
    required String comportamiento,
    required String cargo,
    required double valor,
    required List<String> sistemas,
  }) {
    final dimensionId = dimension;
    _tablaDatos[dimensionId] ??= {};
    _tablaDatos[dimensionId]![evaluacionId] ??= [];

    final existingData = _tablaDatos[dimensionId]![evaluacionId]!.firstWhere(
      (item) => item['comportamiento'] == comportamiento,
      orElse: () => {},
    );

    if (existingData.isNotEmpty) {
      existingData['valor'] = valor;
      existingData['sistemas'] = sistemas;
    } else {
      _tablaDatos[dimensionId]![evaluacionId]!.add({
        'principio': principio,
        'comportamiento': comportamiento,
        'cargo': cargo,
        'valor': valor,
        'sistemas': sistemas,
      });
    }

    debugPrint('Dato actualizado en la dimensión $dimensionId para la evaluación $evaluacionId.');
    notifyListeners();
  }

  double getPromedio(String dimensionId, String comportamiento, String nivel) {
    if (!_tablaDatos.containsKey(dimensionId) || !_tablaDatos[dimensionId]!.containsKey(nivel)) {
      debugPrint('Datos no encontrados para la dimensión $dimensionId y nivel $nivel.');
      return 0.0;
    }

    final datos = _tablaDatos[dimensionId]![nivel]!
        .where((item) => item['comportamiento'] == comportamiento)
        .toList();

    if (datos.isEmpty) {
      debugPrint('No hay datos para el comportamiento $comportamiento en la dimensión $dimensionId y nivel $nivel.');
      return 0.0;
    }

    final suma = datos.fold(0.0, (acc, item) => acc + (item['valor'] as num).toDouble());
    return suma / datos.length;
  }
}
