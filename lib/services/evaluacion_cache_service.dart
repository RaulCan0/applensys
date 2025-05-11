import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente = 'evaluacion_pendiente';
  static const _keyTablaDatos = 'tabla_datos';

  /// Guarda localmente el ID de la evaluación pendiente
  Future<void> guardarPendiente(String evaluacionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  /// Obtiene el ID de la evaluación que quedó pendiente (si hay)
  Future<String?> obtenerPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEvaluacionPendiente);
  }

  /// Elimina el registro de evaluación pendiente y datos de tabla
  Future<void> eliminarPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEvaluacionPendiente);
    await prefs.remove(_keyTablaDatos);
  }

  /// Guarda las tablas completas de progreso (estructura tabladatos)
  Future<void> guardarTablas(Map<String, Map<String, List<Map<String, dynamic>>>> data) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(data.map((dim, map) => MapEntry(
      dim, map.map((id, fila) => MapEntry(id, fila)),
    )));
    await prefs.setString(_keyTablaDatos, encoded);
  }

  /// Carga las tablas completas desde cache
  Future<Map<String, Map<String, List<Map<String, dynamic>>>>> cargarTablas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTablaDatos);
    if (raw == null) {
      return {
      'Dimensión 1': {},
      'Dimensión 2': {},
      'Dimensión 3': {},
    };
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((dim, map) {
      final sub = (map as Map<String, dynamic>).map((id, fila) =>
          MapEntry(id, List<Map<String, dynamic>>.from(fila)));
      return MapEntry(dim, sub);
    });
  }
}
