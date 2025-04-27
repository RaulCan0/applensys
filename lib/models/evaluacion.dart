class Evaluacion {
  final String id;
  final String empresaId;
  final String asociadoId;
  final DateTime fecha;

  Evaluacion({
    required this.id,
    required this.empresaId,
    required this.asociadoId,
    required this.fecha,
  });

  factory Evaluacion.fromMap(Map<String, dynamic> map) {
    return Evaluacion(
      id: map['id'],
      empresaId: map['empresa_id'],
      asociadoId: map['asociado_id'],
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa_id': empresaId,
      'asociado_id': asociadoId,
      'fecha': fecha.toIso8601String(),
    };
  }
}
