class Calificacion {
  final String id;
  final String idAsociado;
  final String idEmpresa;
  final int idDimension; // INTEGER en la base de datos
  final String comportamiento;
  final int puntaje;
  final DateTime fechaEvaluacion;
  final String? observaciones;

  Calificacion({
    required this.id,
    required this.idAsociado,
    required this.idEmpresa,
    required this.idDimension,
    required this.comportamiento,
    required this.puntaje,
    required this.fechaEvaluacion,
    this.observaciones,
  });

  factory Calificacion.fromMap(Map<String, dynamic> map) {
    return Calificacion(
      id: map['id'],
      idAsociado: map['id_asociado'],
      idEmpresa: map['id_empresa'],
      idDimension:
          map['id_dimension'] is int
              ? map['id_dimension']
              : int.parse(map['id_dimension']()),
      comportamiento: map['comportamiento'],
      puntaje: map['puntaje'],
      fechaEvaluacion: DateTime.parse(map['fecha_evaluacion']),
      observaciones: map['observaciones'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'id_asociado': idAsociado,
      'id_empresa': idEmpresa,
      'id_dimension': idDimension,
      'comportamiento': comportamiento,
      'puntaje': puntaje,
      'fecha_evaluacion': fechaEvaluacion.toIso8601String(),
      'observaciones': observaciones,
    };
  }
}
