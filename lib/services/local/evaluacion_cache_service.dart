import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente      = 'evaluacion_pendiente';
  static const _keyTablaDatos               = 'tabla_datos';
  static const _keyRegistrosDatos           = 'registros_datos'; // NUEVO
  static const _keyEvaluacionAsociados      = 'evaluacion_asociados';
  static const _keyEvaluacionPrincipios     = 'evaluacion_principios';
  static const _keyEvaluacionComportamientos= 'evaluacion_comportamientos';
  static const _keyEvaluacionDetalles       = 'evaluacion_detalles';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> guardarPendiente(String evaluacionId) async {
    await init();
    await _prefs!.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  Future<String?> obtenerPendiente() async {
    await init();
    return _prefs!.getString(_keyEvaluacionPendiente);
  }

  Future<void> eliminarPendiente() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
    await _prefs!.remove(_keyTablaDatos);
  }

  /// Guarda las tablas completas de progreso (estructura tablaDatos)
  Future<void> guardarTablas(
    Map<String, Map<String, List<Map<String, dynamic>>>> data
  ) async {
    await init();
    final encoded = jsonEncode(data.map((dim, map) =>
      MapEntry(dim, map.map((id, filas) => MapEntry(id, filas)))
    ));
    await _prefs!.setString(_keyTablaDatos, encoded);
  }

  /// Carga las tablas completas desde cache
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarTablas() async {
    await init();
    final raw = _prefs!.getString(_keyTablaDatos);
    if (raw == null || raw.isEmpty) {
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((dim, map) {
        final sub = (map as Map<String, dynamic>).map((id, filas) =>
          MapEntry(id, List<Map<String, dynamic>>.from(
            (filas as List).map((e) => Map<String, dynamic>.from(e)),
          ))
        );
        return MapEntry(dim, sub);
      });
    } catch (e) {
      // Si hay error, retorna estructura vacía
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }
  }

  /// NUEVO: guarda los registros (registro por registro) sin alterar tablas
  Future<void> guardarRegistros(
    Map<String, Map<String, List<Map<String, dynamic>>>> data
  ) async {
    await init();
    final encoded = jsonEncode(data.map((dim, map) =>
      MapEntry(dim, map.map((id, filas) => MapEntry(id, filas)))
    ));
    await _prefs!.setString(_keyRegistrosDatos, encoded);
  }

  /// NUEVO: carga los registros completos desde cache
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarRegistros() async {
    await init();
    final raw = _prefs!.getString(_keyRegistrosDatos);
    if (raw == null || raw.isEmpty) {
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((dim, map) {
        final sub = (map as Map<String, dynamic>).map((id, filas) =>
          MapEntry(id, List<Map<String, dynamic>>.from(
            (filas as List).map((e) => Map<String, dynamic>.from(e)),
          ))
        );
        return MapEntry(dim, sub);
      });
    } catch (e) {
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }
  }

  /// NUEVO: elimina solo los registros de cache
  Future<void> limpiarRegistros() async {
    await init();
    await _prefs!.remove(_keyRegistrosDatos);
  }

  /// Limpia todo lo relacionado con una evaluación en progreso
  Future<void> limpiarEvaluacionCompleta() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
    await _prefs!.remove(_keyTablaDatos);
    await _prefs!.remove(_keyRegistrosDatos);           // YA INCLUYE registros
    await _prefs!.remove(_keyEvaluacionAsociados);
    await _prefs!.remove(_keyEvaluacionPrincipios);
    await _prefs!.remove(_keyEvaluacionComportamientos);
    await _prefs!.remove(_keyEvaluacionDetalles);
  }
}
