import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente = 'evaluacion_pendiente';
  static const _keyTablaDatos = 'tabla_datos';
  static const _keyEvaluacionAsociados = 'evaluacion_asociados';
  static const _keyEvaluacionPrincipios = 'evaluacion_principios';
  static const _keyEvaluacionComportamientos = 'evaluacion_comportamientos';
  static const _keyEvaluacionDetalles = 'evaluacion_detalles';

  SharedPreferences? _prefs;

  /// Inicializa el servicio y cachea SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Guarda localmente el ID de la evaluación pendiente
  Future<void> guardarPendiente(String evaluacionId) async {
    await init();
    await _prefs!.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  /// Obtiene el ID de la evaluación que quedó pendiente (si hay)
  Future<String?> obtenerPendiente() async {
    await init();
    return _prefs!.getString(_keyEvaluacionPendiente);
  }

  /// Elimina el registro de evaluación pendiente y datos de tabla
  Future<void> eliminarPendiente() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
    await _prefs!.remove(_keyTablaDatos);
  }

  /// Guarda las tablas completas de progreso (estructura tablaDatos)
  Future<void> guardarTablas(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    await init();
    final encoded = jsonEncode(data.map((dim, map) => MapEntry(
      dim, map.map((id, fila) => MapEntry(id, fila)),
    )));
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
        final sub = (map as Map<String, dynamic>).map((id, fila) =>
          MapEntry(id, List<Map<String, dynamic>>.from(
            (fila as List).map((e) => Map<String, dynamic>.from(e)),
          )));
        return MapEntry(dim, sub);
      });
    } catch (e) {
      ('Error al cargar tablaDatos desde cache: $e');
      return {
        'Dimensión 1': {},
        'Dimensión 2': {},
        'Dimensión 3': {},
      };
    }
  }

  /// Limpia todo lo relacionado con una evaluación en progreso
  Future<void> limpiarEvaluacionCompleta() async {
    await init();
    await _prefs!.remove(_keyEvaluacionPendiente);
    await _prefs!.remove(_keyTablaDatos);
    await _prefs!.remove(_keyEvaluacionAsociados);
    await _prefs!.remove(_keyEvaluacionPrincipios);
    await _prefs!.remove(_keyEvaluacionComportamientos);
    await _prefs!.remove(_keyEvaluacionDetalles);
  }
}
