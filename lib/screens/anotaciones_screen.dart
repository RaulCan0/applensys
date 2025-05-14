import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:applensys/services/anotaciones_service.dart';

class AnotacionesScreen extends StatefulWidget {
  const AnotacionesScreen({super.key, required String userId});

  @override
  State<AnotacionesScreen> createState() => _AnotacionesScreenState();
}

class _AnotacionesScreenState extends State<AnotacionesScreen> {
  final AnotacionesService _service = AnotacionesService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _anotaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarAnotaciones();
  }

  Future<void> _cargarAnotaciones() async {
    setState(() => _isLoading = true);
    try {
      _anotaciones = await _service.obtenerAnotaciones();
    } catch (e) {
      _mostrarError('Error al cargar anotaciones: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _agregarAnotacion({String? archivoPath}) async {
    final titulo = _tituloController.text.trim();
    final contenido = _contenidoController.text.trim();

    if (titulo.isEmpty) {
      _mostrarError('El título es obligatorio.');
      return;
    }

    try {
      await _service.agregarAnotacion(
        titulo: titulo,
        contenido: contenido.isNotEmpty ? contenido : null,
        archivoPath: archivoPath,
      );
      _tituloController.clear();
      _contenidoController.clear();
      _cargarAnotaciones();
    } catch (e) {
      _mostrarError('Error al agregar anotación: $e');
    }
  }

  Future<void> _eliminarAnotacion(int id) async {
    try {
      await _service.eliminarAnotacion(id);
      _cargarAnotaciones();
    } catch (e) {
      _mostrarError('Error al eliminar anotación: $e');
    }
  }

  Future<void> _seleccionarArchivo() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    _agregarAnotacion(archivoPath: file.path);
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Anotaciones'),
        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _anotaciones.length,
              itemBuilder: (context, index) {
                final anotacion = _anotaciones[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(anotacion['titulo']),
                    subtitle: anotacion['contenido'] != null
                        ? Text(anotacion['contenido'])
                        : anotacion['archivoPath'] != null
                            ? Image.file(File(anotacion['archivoPath']))
                            : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _eliminarAnotacion(anotacion['id']),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => Padding(
            padding: MediaQuery.of(context).viewInsets,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contenidoController,
                      decoration: const InputDecoration(labelText: 'Contenido (opcional)'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _seleccionarArchivo,
                      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 35, 47, 112),
                      foregroundColor: Colors.white, // Letra color blanco
                      ),
                      child: const Text('Seleccionar Archivo'),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _agregarAnotacion(),
                      style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 35, 47, 112),
                      foregroundColor: Colors.white, // Letra color blanco
                      ),
                      child: const Text('Guardar Anotación'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
