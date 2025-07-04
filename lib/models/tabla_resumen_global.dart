
class ScoreNivel {
  final int nivel;                  // 1=Ejecutivo,2=Gerente,3=Miembro
  final int puntosObtenidos;
  final int puntosPosibles;
  final double porcentaje;          // 0–100

  ScoreNivel({
    required this.nivel,
    required this.puntosObtenidos,
    required this.puntosPosibles,
    required this.porcentaje,
  });
}
   