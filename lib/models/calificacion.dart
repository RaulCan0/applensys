class Calificacion {
  final String id;
  final String idAsociado;
  final String comportamiento;
  final int puntaje;

  Calificacion({
    required this.id,
    required this.idAsociado,
    required this.comportamiento,
    required this.puntaje,
  });

  factory Calificacion.fromMap(Map<String, dynamic> map) {
    return Calificacion(
      id: map['id'],
      idAsociado: map['id_asociado'],
      comportamiento: map['comportamiento'],
      puntaje: map['puntaje'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_asociado': idAsociado,
      'criterio': comportamiento,
      'puntaje': puntaje,
    };
  }
}
