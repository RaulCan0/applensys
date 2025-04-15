class Empresa {
  final String id;
  final String nombre;
  final String tamano;
  final int empleadosTotal;
  final List empleadosAsociados;
  final String unidades;
  final int areas;
  final String sector;

  Empresa({
    required this.id,
    required this.nombre,
    required this.tamano,
    required this.empleadosTotal,
    this.empleadosAsociados = const [],
    required this.unidades,
    required this.areas,
    required this.sector,
  });

  factory Empresa.fromMap(Map<String, dynamic> map) {
    return Empresa(
      id: map['id'],
      nombre: map['nombre'],
      tamano: map['tamano'],
      empleadosTotal: map['empleados_total'] ?? 0,
      empleadosAsociados: map['empleados_asociados'] ?? [],
      unidades: map['unidades'],
      areas: map['areas'] ?? 0,
      sector: map['sector'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'tamano': tamano,
      'empleados_total': empleadosTotal,
      'empleados_asociados': empleadosAsociados,
      'unidades': unidades,
      'areas': areas,
      'sector': sector,
    };
  }
}
