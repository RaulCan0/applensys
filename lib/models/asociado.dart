import 'dart:convert';

class Asociado {
  final String id;
  final String nombre;
  final String cargo;
  final String empresaId;
  final List<String> empleadosAsociados;
  final Map<String, double> progresoDimensiones;
  final Map<String, dynamic> comportamientosEvaluados;
  final int antiguedad;

  Asociado({
    required this.id,
    required this.nombre,
    required this.cargo,
    required this.empresaId,
    required this.empleadosAsociados,
    required this.progresoDimensiones,
    required this.comportamientosEvaluados,
    required this.antiguedad,
  });

  factory Asociado.fromMap(Map<String, dynamic> map) {
    return Asociado(
      id: map['id'],
      nombre: map['nombre'],
      cargo: map['cargo'],
      empresaId: map['empresa_id'],
      empleadosAsociados: map['empleados_asociados'] is String
          ? List<String>.from(jsonDecode(map['empleados_asociados']))
          : List<String>.from(map['empleados_asociados'] ?? []),
      progresoDimensiones: map['progreso_dimensiones'] is String
          ? Map<String, double>.from(jsonDecode(map['progreso_dimensiones']))
          : Map<String, double>.from(map['progreso_dimensiones'] ?? {}),
      comportamientosEvaluados: map['comportamientos_evaluados'] is String
          ? Map<String, dynamic>.from(jsonDecode(map['comportamientos_evaluados']))
          : Map<String, dynamic>.from(map['comportamientos_evaluados'] ?? {}),
      antiguedad: map['antiguedad'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'cargo': cargo,
      'empresa_id': empresaId,
      'empleados_asociados': empleadosAsociados,
      'progreso_dimensiones': progresoDimensiones,
      'comportamientos_evaluados': comportamientosEvaluados,
      'antiguedad': antiguedad,
    };
  }

  void limpiarProgreso() {
    progresoDimensiones.clear();
    comportamientosEvaluados.clear();
  }
}
