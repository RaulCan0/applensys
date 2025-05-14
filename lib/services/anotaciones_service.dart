import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

class AnotacionesService {
  Future<List<Map<String, dynamic>>> obtenerAnotaciones() async {
    final prefs = await SharedPreferences.getInstance();
    final anotacionesJson = prefs.getString('anotaciones') ?? '[]';
    return List<Map<String, dynamic>>.from(json.decode(anotacionesJson));
  }

  Future<void> agregarAnotacion({
    required String titulo,
    String? contenido,
    String? archivoPath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final anotaciones = await obtenerAnotaciones();

    final nuevaAnotacion = {
      'id': DateTime.now().millisecondsSinceEpoch,
      'titulo': titulo,
      'contenido': contenido,
      'archivoPath': archivoPath,
      'createdAt': DateTime.now().toIso8601String(),
    };

    anotaciones.add(nuevaAnotacion);
    await prefs.setString('anotaciones', json.encode(anotaciones));
  }

  Future<void> eliminarAnotacion(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final anotaciones = await obtenerAnotaciones();

    anotaciones.removeWhere((anotacion) => anotacion['id'] == id);
    await prefs.setString('anotaciones', json.encode(anotaciones));
  }
}
