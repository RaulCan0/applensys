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
    double? general, required String nivel,
  }) : general = general ?? ((ejecutivo + gerente + miembro) / 3.0);

  factory LevelAverages.fromMap(Map<String, dynamic> map) {
    final ejecutivo = (map['ejecutivo'] as num?)?.toDouble() ?? 0.0;
    final gerente = (map['gerente'] as num?)?.toDouble() ?? 0.0;
    final miembro = (map['miembro'] as num?)?.toDouble() ?? 0.0;

    return LevelAverages(
      id: map['id'] as int,
      nombre: map['nombre'] as String,
      ejecutivo: ejecutivo,
      gerente: gerente,
      miembro: miembro,
      dimensionId: map['dimensionId'] != null ? map['dimensionId'] as int : null,
      general: map['general'] != null
          ? (map['general'] as num).toDouble()
          : ((ejecutivo + gerente + miembro) / 3.0), nivel: '',
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
    };
  }
}
