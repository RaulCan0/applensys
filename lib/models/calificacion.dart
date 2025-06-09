import 'dart:convert';

class Calificacion {
  final String id;
  final String idAsociado;
  final String idEmpresa;
  final int idDimension; 
  final String comportamiento;
  final int puntaje;
  final DateTime fechaEvaluacion;
  final String? observaciones;
  final List<String> sistemas;
  final String? evidenciaUrl; // Agregado campo de URL de evidencia

  Calificacion({
    required this.id,
    required this.idAsociado,
    required this.idEmpresa,
    required this.idDimension,
    required this.comportamiento,
    required this.puntaje,
    required this.fechaEvaluacion,
    this.observaciones,
    required this.sistemas,
    this.evidenciaUrl,
  });

  factory Calificacion.fromMap(Map<String, dynamic> map) {
    List<String> sistemasDesdeMapa = [];
    if (map['sistemas'] is List) {
      sistemasDesdeMapa = List<String>.from(map['sistemas']);
    } else if (map['sistemas'] is String && (map['sistemas'] as String).isNotEmpty) {
      try {
        sistemasDesdeMapa = List<String>.from(jsonDecode(map['sistemas']));
      } catch (_) {
        sistemasDesdeMapa = [];
      }
    }

    return Calificacion(
      id: map['id'] as String,
      idAsociado: map['id_asociado'] as String,
      idEmpresa: map['id_empresa'] as String,
      idDimension: map['id_dimension'] is int
          ? map['id_dimension'] as int
          : int.parse(map['id_dimension'].toString()),
      comportamiento: map['comportamiento'] as String,
      puntaje: map['puntaje'] as int,
      fechaEvaluacion: DateTime.parse(map['fecha_evaluacion'] as String),
      observaciones: map['observaciones'] as String?,
      sistemas: sistemasDesdeMapa,
      evidenciaUrl: map['evidencia_url'] as String?,
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
      'sistemas': sistemas,
      'evidencia_url': evidenciaUrl,
    };
  }
}
