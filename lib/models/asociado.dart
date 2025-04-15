class Asociado {
  final String id;
  final String nombre;
  final String cargo;
  final String empresaId;

  Asociado({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.empresaId,
  });

  factory Asociado.fromMap(Map<String, dynamic> map) {
    return Asociado(
      id: map['id'],
      nombre: map['nombre'],
      cargo: map['cargo'],
      empresaId: map['empresa_id'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'cargo': cargo,
      'empresa_id': empresaId,
    };
  }
}
