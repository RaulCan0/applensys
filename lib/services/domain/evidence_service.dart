// lib/services/domain/evidence_service.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio para subir y gestionar evidencias (imágenes) sin afectar otros servicios.
class EvidenceService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();

  /// Selecciona un archivo de imagen desde el sistema de archivos (Windows, macOS, Linux)
  /// y lo sube al bucket 'evidencias'.
  Future<String?> uploadFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
    final Uint8List? bytes = file.bytes;
    if (bytes == null) return null;

    await _supabase.storage
        .from('evidencias')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            contentType: file.extension != null
                ? 'image/${file.extension}'
                : 'image/jpeg',
          ),
        );

    // getPublicUrl retorna directamente la URL pública como String
    final String publicUrl = _supabase.storage.from('evidencias').getPublicUrl(fileName);
    return publicUrl;
  }

  /// Toma una foto con la cámara del dispositivo (móvil o desktop si esté soportado)
  /// y la sube al bucket 'evidencias'.
  Future<String?> uploadFromCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return null;
    final Uint8List bytes = await photo.readAsBytes();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';

    await _supabase.storage
        .from('evidencias')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );

    final String publicUrl = _supabase.storage.from('evidencias').getPublicUrl(fileName);
    return publicUrl;
  }
}
