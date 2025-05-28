// anotaciones_service.dart
// ignore_for_file: avoid_print

import 'dart:async'; // Necesario para StreamController o Stream.value

class AnotacionesService {
  // Lista en memoria para simular el almacenamiento de anotaciones
  final List<Map<String, dynamic>> _anotacionesSimuladas = [];
  int _nextId = 1;

  // StreamController para emitir actualizaciones de las anotaciones
  final _anotacionesController = StreamController<List<Map<String, dynamic>>>.broadcast();

  // Stream de anotaciones
  Stream<List<Map<String, dynamic>>> streamAnotaciones() {
    // Emitir la lista actual inmediatamente y luego en cada cambio
    Future.delayed(Duration.zero, () {
      _anotacionesController.add(List.unmodifiable(_anotacionesSimuladas));
    });
    return _anotacionesController.stream;
  }

  // Agregar anotación
  Future<void> agregarAnotacion({
    required String titulo,
    String? contenido,
    String? archivoPath,
    String categoria = 'General', // Añadido para ejemplo, ajusta según tu modelo
  }) async {
    final nuevaAnotacion = {
      'id': _nextId++,
      'titulo': titulo,
      'contenido': contenido ?? '',
      'archivoPath': archivoPath,
      'categoria': categoria, // Asegúrate que tu modelo de datos lo maneje
    };
    _anotacionesSimuladas.add(nuevaAnotacion);
    _anotacionesController.add(List.unmodifiable(_anotacionesSimuladas)); // Notificar a los oyentes
    // Simulación de operación asíncrona
    await Future.delayed(const Duration(milliseconds: 100));
    print('Anotación agregada: $nuevaAnotacion');
  }

  // Eliminar anotación
  Future<void> eliminarAnotacion(int id) async {
    _anotacionesSimuladas.removeWhere((anotacion) => anotacion['id'] == id);
    _anotacionesController.add(List.unmodifiable(_anotacionesSimuladas)); // Notificar a los oyentes
    // Simulación de operación asíncrona
    await Future.delayed(const Duration(milliseconds: 100));
    print('Anotación eliminada con id: $id');
  }

  // Método para cerrar el StreamController cuando ya no se necesite (opcional, depende de la gestión del ciclo de vida del servicio)
  void dispose() {
    _anotacionesController.close();
  }
}
