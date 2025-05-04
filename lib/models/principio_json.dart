class PrincipioJson {
  final String nombre;
  final String benchmarkComportamiento;
  final String benchmarkPorNivel;
  final String nivel;
  final String preguntas;
  final Map<String, String> calificaciones;
  final List<String> comportamientos;

  PrincipioJson({
    required this.nombre,
    required this.benchmarkComportamiento,
    required this.benchmarkPorNivel,
    required this.nivel,
    required this.preguntas,
    required this.calificaciones,
    required this.comportamientos,
  });

  factory PrincipioJson.fromJson(Map<String, dynamic> json) {
    return PrincipioJson(
      nombre: json['PRINCIPIOS'] ?? '',
      benchmarkComportamiento: json['BENCHMARK DE COMPORTAMIENTOS'] ?? '',
      benchmarkPorNivel: json['BENCHMARK POR NIVEL'] ?? '',
      nivel: json['NIVEL'] ?? '',
      preguntas: json['GUÍA DE PREGUNTAS'] ?? '',
      calificaciones: {
        'C1': json['C1'] ?? '',
        'C2': json['C2'] ?? '',
        'C3': json['C3'] ?? '',
        'C4': json['C4'] ?? '',
        'C5': json['C5'] ?? '',
      },
      comportamientos:
          json['comportamientos'] != null
              ? List<String>.from(json['comportamientos'])
              : [], // Si es null, asignamos una lista vacía
    );
  }

  
}
