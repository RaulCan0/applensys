import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para manejo de archivos en Supabase Storage
class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Sube un archivo binario al bucket especificado
  Future<void> uploadFile({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String contentType = 'application/octet-stream',
  }) async {
    await _client.storage.from(bucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType),
    );
  }

  /// Obtiene la URL pública de un archivo en el bucket
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    final res = _client.storage.from(bucket).getPublicUrl(path);
    if (res.isEmpty) {
      throw Exception('No se pudo generar la URL pública para $path');
    }
    return res;
  }
}
