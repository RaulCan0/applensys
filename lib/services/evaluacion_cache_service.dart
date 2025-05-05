// lib/services/evaluacion_cache_service.dart

import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente = 'evaluacion_pendiente';

  Future<void> guardarPendiente(String evaluacionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  Future<String?> obtenerPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEvaluacionPendiente);
  }

  Future<void> eliminarPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEvaluacionPendiente);
  }
}
