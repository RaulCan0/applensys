import 'package:applensys/models/calificacion.dart';
import 'package:applensys/services/domain/supabase_service.dart';
 
class CalificacionService {
  final SupabaseService _remote = SupabaseService();
 
  Future<void> addCalificacion(Calificacion calificacion) async {
    await _remote.addCalificacion(
      calificacion,
      id: calificacion.id,
      idAsociado: calificacion.idAsociado,
    );
  }
 
  Future<void> updateCalificacion(String id, int nuevoPuntaje) async {
    await _remote.updateCalificacion(id, nuevoPuntaje);
  }
 
  Future<void> updateCalificacionFull(Calificacion calificacion) async {
    await _remote.updateCalificacionFull(calificacion);
  }
 
  Future<void> deleteCalificacion(String id) async {
    await _remote.deleteCalificacion(id);
  }
 
  Future<List<Calificacion>> getCalificacionesPorAsociado(String idAsociado) async {
    return await _remote.getCalificacionesPorAsociado(idAsociado);
  }
 
  Future<Calificacion?> getCalificacionExistente({
    required String idAsociado,
    required String idEmpresa,
    required int idDimension,
    required String comportamiento,
  }) async {
    final lista = await getCalificacionesPorAsociado(idAsociado);
    return lista.cast<Calificacion?>().firstWhere(
      (c) => c != null &&
             c.idEmpresa == idEmpresa &&
             c.idDimension == idDimension &&
             c.comportamiento == comportamiento,
      orElse: () => null,
    );
  }
 }
