class PrincipioJson {
  final String nombre;
  final String benchmarkComportamiento;
  final String benchmarkPorCargo;
  final String cargo;
  final String preguntas;
  final Map<String, String> calificaciones;
  final List<String> comportamientos;

  PrincipioJson({
    required this.nombre,
    required this.benchmarkComportamiento,
    required this.benchmarkPorCargo,
    required this.cargo,
    required this.preguntas,
    required this.calificaciones,
    required this.comportamientos,
  });

  factory PrincipioJson.fromJson(Map<String, dynamic> json) {
    return PrincipioJson(
      nombre: json['PRINCIPIOS'] as String? ?? '',
      benchmarkComportamiento: json['BENCHMARK DE COMPORTAMIENTOS'] as String? ?? '',
      benchmarkPorCargo: json['BENCHMARK POR NIVEL'] as String? ?? '',
      cargo: json['NIVEL'] as String? ?? '',
      preguntas: json['GUÍA DE PREGUNTAS'] as String? ?? '',
      calificaciones: {
        'C1': json['C1'] as String? ?? '',
        'C2': json['C2'] as String? ?? '',
        'C3': json['C3'] as String? ?? '',
        'C4': json['C4'] as String? ?? '',
        'C5': json['C5'] as String? ?? '',
      },
      comportamientos: json['comportamientos'] != null
          ? List<String>.from(json['comportamientos'] as List)
          : <String>[],
    );
  }
}
