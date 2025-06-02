
class Comportamiento {
  final String nombre;
  final double promedioEjecutivo;
  final double promedioGerente;
  final double promedioMiembro;

  Comportamiento({
    required this.nombre,
    required this.promedioEjecutivo,
    required this.promedioGerente,
    required this.promedioMiembro,
  });
}

class Principio {
  final String nombre;
  final double promedioGeneral;
  final List<Comportamiento> comportamientos;

  Principio({
    required this.nombre,
    required this.promedioGeneral,
    required this.comportamientos,
  });
}

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
