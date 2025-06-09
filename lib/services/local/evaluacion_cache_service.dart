import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente      = 'evaluacion_pendiente';
  static const _keyTablaDatos               = 'tabla_datos';
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
    // Ya no eliminamos _keyTablaDatos aquí para que persistan los datos de la tabla
    // await _prefs!.remove(_keyTablaDatos); 
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

  /// NUEVO: elimina solo los datos de tabla de cache
  Future<void> limpiarCacheTablaDatos() async {
    await init();
    await _prefs!.remove(_keyTablaDatos);
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
Future<List<Map<String, dynamic>>> cargarPromediosSistemas() async {
    final tabla = await cargarTablas(); 
    final Map<String, List<double>> acumulador = {};
    tabla.forEach((_, submap) {
      submap.values.expand((rows) => rows).forEach((item) {
        final sistema = item['sistema'] as String? ?? '';
        final raw = item['valor'];
        final valor = raw is num
            ? raw.toDouble()
            : double.tryParse(raw.toString()) ?? 0.0;
        if (sistema.isNotEmpty) {
          acumulador.putIfAbsent(sistema, () => []).add(valor);
        }
      });
    });
    return acumulador.entries.map((e) {
      final lista = e.value;
      final suma = lista.fold<double>(0, (a, b) => a + b);
      final promedio = lista.isNotEmpty ? suma / lista.length : 0.0;
      return {'sistema': e.key, 'valor': promedio};
    }).toList();
  }}