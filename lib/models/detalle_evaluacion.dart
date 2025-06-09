class DetalleEvaluacion {
  final String id;
  final String evaluacionId;
  final String comportamientoId;
  final int cargo; // 1=Ejecutivo, 2=Gerente, 3=Equipo
  final int calificacion;
  final String observacion;
  final List<String> sistemas; // <- NUEVO

  DetalleEvaluacion({
    required this.id,
    required this.evaluacionId,
    required this.comportamientoId,
    required this.cargo,
    required this.calificacion,
    required this.observacion,
    required this.sistemas, // <- NUEVO
  });
}
