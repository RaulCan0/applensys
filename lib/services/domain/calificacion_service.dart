import 'package:applensys/models/calificacion.dart';

class CalificacionService {
  final List<Calificacion> _calificaciones = [];

  Future<void> addCalificacion(Calificacion calificacion) async {
    _calificaciones.add(calificacion);
  }

  Future<void> updateCalificacion(String id, int puntaje) async {
    // Implementación pendiente o ajustada según necesidades
    throw UnimplementedError();
  }

  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    final index = _calificaciones.indexWhere((c) => c.id == calificacion.id);
    if (index != -1) {
      _calificaciones[index] = calificacion;
    } else {
      throw Exception('Calificación no encontrada');
    }
  }

  Future<void> deleteCalificacion(String id) async {
    // Implementación pendiente o ajustada según necesidades
    throw UnimplementedError();
  }

  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    // Implementación pendiente o ajustada según necesidades
    throw UnimplementedError();
  }

  Future<Calificacion?> getCalificacionExistente({
    required String idAsociado,
    required String idEmpresa,
    required int idDimension,
    required String comportamiento,
  }) async {
    for (final calificacion in _calificaciones) {
      if (calificacion.idAsociado == idAsociado &&
          calificacion.idEmpresa == idEmpresa &&
          calificacion.idDimension == idDimension &&
          calificacion.comportamiento == comportamiento) {
        return calificacion;
      }
    }
    return null;
  }
}
