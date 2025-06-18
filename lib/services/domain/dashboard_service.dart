import 'dart:collection';

class DashboardService {
  final Map<String, Map<String, Map<String, Map<String, List<int>>>>> _data = {};

  // Getter para acceder a la estructura de datos de forma segura.
  // Devuelve una copia no modificable para evitar cambios externos accidentales.
  Map<String, Map<String, Map<String, Map<String, List<int>>>>> get estructura => 
      UnmodifiableMapView(_data);

  DashboardService() {
    final estructuraBase = {
      "IMPULSORES CULTURALES": {
        "Respetar a Cada Individuo": ["Soporte", "Reconocer", "Comunidad"],
        "Liderar con Humildad": ["Liderazgo de Servidor", "Valorar", "Empoderar"]
      },
      "MEJORA CONTINUA": {
        "Buscar la Perfección": ["Mentalidad", "Estructura"],
        "Abrazar el Pensamiento Científico": ["Reflexionar", "Análisis", "Colaborar"],
        "Enfocarse en el Proceso": ["Comprender", "Diseño", "Atribución"],
        "Asegurar la Calidad en la Fuente": ["A Prueba de Errores", "Propiedad", "Conectar"],
        "Mejorar el Flujo y Jalón de Valor": ["Ininterrumpido", "Demanda", "Eliminar"]
      },
      "ALINEAMIENTO EMPRESARIAL": {
        "Pensar Sistémicamente": ["Optimizar", "Impacto"],
        "Crear Constancia de Propósito": ["Alinear", "Aclarar", "Comunicar"],
        "Crear Valor para el Cliente": ["Relación", "Valor", "Medida"]
      }
    };

    estructuraBase.forEach((dimension, principios) {
      _data[dimension] = {};
      principios.forEach((principio, comportamientos) {
        _data[dimension]![principio] = {};
        for (var comportamiento in comportamientos) {
          _data[dimension]![principio]![comportamiento] = {
            "Ejecutivo": [],
            "Gerente": [],
            "Miembro": []
          };
        }
      });
    });
  }

  void registrarEvaluacion({
    required String dimension,
    required String principio,
    required String comportamiento,
    required String nivel,
    required int valor,
  }) {
    _data[dimension]?[principio]?[comportamiento]?[nivel]?.add(valor);
  }

  double _promedio(List<int> valores) =>
      valores.isEmpty ? 0.0 : valores.reduce((a, b) => a + b) / valores.length;

  double obtenerPromedioComportamiento(String d, String p, String c, String nivel) {
    return _promedio(_data[d]?[p]?[c]?[nivel] ?? []);
  }

  double obtenerPromedioPrincipio(String d, String p, String nivel) {
    final comportamientos = _data[d]?[p];
    if (comportamientos == null) return 0.0;

    final promedios = comportamientos.entries
        .map((e) => obtenerPromedioComportamiento(d, p, e.key, nivel))
        .toList();
    return _promedio(promedios.cast<int>());
  }

  double obtenerPromedioDimension(String d, String nivel) {
    final principios = _data[d];
    if (principios == null) return 0.0;

    final promedios = principios.entries
        .map((e) => obtenerPromedioPrincipio(d, e.key, nivel))
        .toList();
    return _promedio(promedios.cast<int>());
  }

  Map<String, dynamic> obtenerResumenPorNivel(String nivel) {
    final resultado = <String, dynamic>{};

    _data.forEach((dimension, principios) {
      final dimResumen = <String, dynamic>{};
      principios.forEach((principio, comportamientos) {
        final prinResumen = <String, double>{};
        comportamientos.forEach((comportamiento, niveles) {
          prinResumen[comportamiento] = _promedio(niveles[nivel] ?? []);
        });
        dimResumen[principio] = {
          "promedio": obtenerPromedioPrincipio(dimension, principio, nivel),
          "comportamientos": prinResumen
        };
      });
      resultado[dimension] = {
        "promedio": obtenerPromedioDimension(dimension, nivel),
        "principios": dimResumen
      };
    });

    return resultado;
  }
}