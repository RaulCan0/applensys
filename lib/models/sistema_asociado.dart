class SistemaAsociado {
  final String id;
  final String nombre;

  SistemaAsociado({
    required this.id,
    required this.nombre,
  });

  factory SistemaAsociado.fromJson(Map<String, dynamic> json) {
    return SistemaAsociado(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
    };
  }

  // Optional: copyWith method for immutability
  SistemaAsociado copyWith({
    String? id,
    String? nombre,
  }) {
    return SistemaAsociado(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SistemaAsociado &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nombre == other.nombre;

  @override
  int get hashCode => id.hashCode ^ nombre.hashCode;

  @override
  String toString() {
    return 'SistemaAsociado{id: $id, nombre: $nombre}';
  }
}
