class Empleado {
  final String id;
  final String nombre;
  final String cargo; // 'ejecutivo', 'gerente', 'miembro'
  final String empresaId;

  Empleado({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.empresaId,
  });
}