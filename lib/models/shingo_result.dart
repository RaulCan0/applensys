import 'dart:io';

class ShingoResultModel {
  Map<String, String> campos;
  File? imagenGrafico;
  int calificacion;

  ShingoResultModel({
    required this.campos,
    required this.imagenGrafico,
    required this.calificacion,
  });
}
