// anotaciones_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

class AnotacionesService {
  final _supabase = Supabase.instance.client;

  // ✅ Realtime stream (funciona sin RLS si realtime está activado en la tabla)
  Stream<List<Map<String, dynamic>>> streamAnotaciones() {
    return _supabase
        .from('anotaciones')
        .stream(primaryKey: ['id']) // importante para actualizaciones
        .order('created_at', ascending: false)
        // ignore: deprecated_member_use
        .execute();
  }

  // ✅ Insertar anotación
  Future<void> agregarAnotacion({
    required String titulo,
    String? contenido,
    String? archivoPath,
  }) async {
    await _supabase.from('anotaciones').insert({
      'titulo': titulo,
      if (contenido != null) 'contenido': contenido,
      if (archivoPath != null) 'archivoPath': archivoPath,
    });
  }

  // ✅ Eliminar anotación
  Future<void> eliminarAnotacion(int id) async {
    await _supabase.from('anotaciones').delete().eq('id', id);
  }
}
