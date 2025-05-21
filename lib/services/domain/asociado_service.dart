import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/models/asociado.dart';

/// Servicio para gestión de asociados
class AsociadoService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Asociado>> getAsociadosPorEmpresa(String empresaId) async {
    final res = await _client.from('asociados').select().eq('empresa_id', empresaId);
    return (res as List).map((e) => Asociado.fromMap(e)).toList();
  }

  Future<void> addAsociado(Asociado asociado) async {
    await _client.from('asociados').insert(asociado.toMap());
  }

  Future<void> updateAsociado(String id, Asociado asociado) async {
    await _client.from('asociados').update(asociado.toMap()).eq('id', id);
  }

  Future<void> deleteAsociado(String id) async {
    await _client.from('asociados').delete().eq('id', id);
  }
}
