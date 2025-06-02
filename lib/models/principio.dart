import 'package:applensys/models/comportamiento.dart';

class Principio {
  final String id;
  final String dimensionId;
  final String nombre;
  final double promedioGeneral;
  final List<Comportamiento> comportamientos;

  Principio({
    required this.id,
    required this.dimensionId,
    required this.nombre,
    required this.promedioGeneral,
    required this.comportamientos,
  });
}
