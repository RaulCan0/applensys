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
        // Corregido: Leer la lista de sistemas de la clave 'sistemas' (plural)
        // y luego iterar sobre cada sistema en esa lista.
        final List<dynamic> sistemasDelItemRaw = item['sistemas'] as List<dynamic>? ?? [];
        final List<String> sistemasDelItem = sistemasDelItemRaw.map((s) => s.toString()).toList();

        final rawValor = item['valor']; // 'valor' es la clave para la calificación/puntaje
        final valorNumerico = rawValor is num
            ? rawValor.toDouble()
            : double.tryParse(rawValor.toString()) ?? 0.0;

        for (final nombreSistema in sistemasDelItem) {
          if (nombreSistema.isNotEmpty) {
            acumulador.putIfAbsent(nombreSistema, () => []).add(valorNumerico);
          }
        }
      });
    });

    final List<Map<String, dynamic>> promedios = [];
    acumulador.forEach((sistema, valores) {
      if (valores.isNotEmpty) {
        final promedio = valores.reduce((a, b) => a + b) / valores.length;
        promedios.add({
          'sistema': sistema,
          'promedio': promedio,
          'cantidad': valores.length,
        });
      }
    });
    // Opcional: ordenar promedios
    promedios.sort((a, b) => (b['promedio'] as double).compareTo(a['promedio'] as double));
    return promedios;
  }
}