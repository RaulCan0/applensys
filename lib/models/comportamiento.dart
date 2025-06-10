class Comportamiento {
  String nombre;
  final double promedioEjecutivo;
  final double promedioGerente;
  final double promedioMiembro;

  Comportamiento({
    required this.nombre,
    required this.promedioEjecutivo,
    required this.promedioGerente,
    required this.promedioMiembro, required List<String> sistemas, required nivel, required String principioId, required String id, required cargo,
  });
}
