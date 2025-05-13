class LevelAverages {
  final int id;
  final String nombre;
  final double ejecutivo;
  final double gerente;
  final double miembro;
  final int? dimensionId;
  final double general;

  LevelAverages({
    required this.id,
    required this.nombre,
    required this.ejecutivo,
    required this.gerente,
    required this.miembro,
    this.dimensionId,
    double? general,
    required String nivel, // <--- Parámetro nivel reintroducido
  }) : general = general ?? ((ejecutivo + gerente + miembro) / 3.0);

  factory LevelAverages.fromMap(Map<String, dynamic> map) {
    final double? rawEjecutivo = (map['ejecutivo'] as num?)?.toDouble();
    final double? rawGerente = (map['gerente'] as num?)?.toDouble();
    final double? rawMiembro = (map['miembro'] as num?)?.toDouble();

    final ejecutivoFinal = rawEjecutivo ?? 0.0;
    final gerenteFinal = rawGerente ?? 0.0;
    final miembroFinal = rawMiembro ?? 0.0;

    double calculatedGeneral;
    if (map['general'] != null) {
      calculatedGeneral = (map['general'] as num).toDouble();
    } else {
      double sum = 0;
      int count = 0;
      if (rawEjecutivo != null) {
        sum += ejecutivoFinal;
        count++;
      }
      if (rawGerente != null) {
        sum += gerenteFinal;
        count++;
      }
      if (rawMiembro != null) {
        sum += miembroFinal;
        count++;
      }
      calculatedGeneral = count > 0 ? sum / count : 0.0;
    }

    return LevelAverages(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      ejecutivo: ejecutivoFinal,
      gerente: gerenteFinal,
      miembro: miembroFinal,
      dimensionId: map['dimensionId'] as int?,
      general: calculatedGeneral,
      nivel: map['nivel'] as String? ?? '', // <--- Parámetro nivel reintroducido, se usa el valor del map o un string vacío
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'ejecutivo': ejecutivo,
      'gerente': gerente,
      'miembro': miembro,
      'dimensionId': dimensionId,
      'general': general,
      // 'nivel': nivel, // Si se quisiera persistir el nivel, se añadiría aquí
    };
  }
}
