import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente = 'evaluacion_pendiente';

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

  /// Elimina el registro de evaluación pendiente
  Future<void> eliminarPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEvaluacionPendiente);
  }
}
