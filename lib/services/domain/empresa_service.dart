import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/models/empresa.dart';

/// Servicio para gestión de empresas
class EmpresaService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Empresa>> getEmpresas() async {
    final res = await _client.from('empresas').select();
    return (res as List).map((e) => Empresa.fromMap(e)).toList();
  }

  Future<void> addEmpresa(Empresa empresa) async {
    await _client.from('empresas').insert(empresa.toMap());
  }

  Future<void> updateEmpresa(String id, Empresa empresa) async {
    await _client.from('empresas').update(empresa.toMap()).eq('id', id);
  }

  Future<void> deleteEmpresa(String id) async {
    await _client.from('empresas').delete().eq('id', id);
  }
}
