import 'package:applensys/models/principio.dart';

class Dimension {
  final String id;
  final String nombre;
  final double promedioGeneral;
  final List<Principio> principios;

  Dimension({
    required this.id,
    required this.nombre,
    required this.promedioGeneral,
    required this.principios,
  });
}