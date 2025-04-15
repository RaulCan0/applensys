class Evaluacion {
  final String id;
  final String empresa;
  final String consultor;
  final DateTime fecha;

  Evaluacion({
    required this.id,
    required this.empresa,
    required this.consultor,
    required this.fecha,
  });

  factory Evaluacion.fromMap(Map<String, dynamic> map) {
    return Evaluacion(
      id: map['id'],
      empresa: map['empresa'],
      consultor: map['consultor'],
      fecha: DateTime.parse(map['fecha']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'empresa': empresa,
      'consultor': consultor,
      'fecha': fecha.toIso8601String(),
    };
  }
}
