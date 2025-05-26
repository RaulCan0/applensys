import 'dart:io';
import 'package:applensys/services/domain/anotaciones_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:applensys/providers/text_size_provider.dart';

const azulLensys = Color(0xFF003056);
const grisClaro = Color(0xFFF1F4F8);

class AnotacionesScreen extends ConsumerStatefulWidget {
  final String userId;
  const AnotacionesScreen({super.key, required this.userId});

  @override
  ConsumerState<AnotacionesScreen> createState() => _AnotacionesScreenState();
}

class _AnotacionesScreenState extends ConsumerState<AnotacionesScreen>
    with SingleTickerProviderStateMixin { // Añadido SingleTickerProviderStateMixin
  final AnotacionesService _service = AnotacionesService();
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _contenidoController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  TabController? _tabController; // Controlador para las pestañas
  final List<String> _categories = ['Todas', 'Trabajo', 'Personal']; // Categorías de ejemplo

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
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
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al agregar anotación: $e');
    }
  }

  Future<void> _seleccionarArchivo() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      _agregarAnotacion(archivoPath: file.path);
    }
  }

  Future<void> _eliminarAnotacion(int id) async {
    try {
      await _service.eliminarAnotacion(id);
    } catch (e) {
      _mostrarError('Error al eliminar: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = textSize / 14.0;

    return Scaffold(
      backgroundColor: grisClaro,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Mis Anotaciones',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              fontSize: 20 * scaleFactor,
              color: Colors.white,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        backgroundColor: azulLensys, // Corregido: Dentro del AppBar
        elevation: 0, // Corregido: Dentro del AppBar
        toolbarHeight: kToolbarHeight * scaleFactor, // Corregido: Dentro del AppBar
        bottom: TabBar( // Añadido: Barra de pestañas para categorías
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _categories.map((String category) {
            return Tab(
              child: Text(
                category,
                style: TextStyle(fontSize: 14 * scaleFactor),
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView( // Modificado: El body ahora es un TabBarView
        controller: _tabController,
        children: _categories.map((String category) {
          // Por ahora, cada pestaña muestra todas las anotaciones.
          // Más adelante, filtraremos por categoría.
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream: _service.streamAnotaciones(), 
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error: \\${snapshot.error}',
                    style: TextStyle(fontSize: 14 * scaleFactor),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return Center(
                  child: SizedBox(
                    width: 24 * scaleFactor,
                    height: 24 * scaleFactor,
                    child: const CircularProgressIndicator(color: azulLensys),
                  ),
                );
              }

              final anotaciones = snapshot.data!;
              if (category != 'Todas') {
                anotaciones.retainWhere((a) => a['categoria'] == category);
              }   
              if (anotaciones.isEmpty) {
                return Center(
                  child: Text(
                    'Sin anotaciones en esta categoría.',
                    style: TextStyle(fontSize: 14 * scaleFactor),
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(12 * scaleFactor),
                itemCount: anotaciones.length,
                itemBuilder: (context, index) {
                  final a = anotaciones[index];
                  return Card(
                    color: Colors.white,
                    margin: EdgeInsets.only(bottom: 12 * scaleFactor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16 * scaleFactor),
                    ),
                    elevation: 3,
                    child: Padding(
                      padding: EdgeInsets.all(16 * scaleFactor),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['titulo'],
                            style: TextStyle(
                                fontSize: 18 * scaleFactor,
                                fontWeight: FontWeight.bold,
                                color: azulLensys), // Color de título
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          if (a['contenido'] != null &&
                              a['contenido'].isNotEmpty)
                            Text(
                              a['contenido'],
                              style: TextStyle(
                                  fontSize: 14 * scaleFactor,
                                  color: Colors.black87),
                            ),
                          if (a['archivoPath'] != null)
                            Padding(
                              padding: EdgeInsets.only(top: 10 * scaleFactor),
                              child: ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(12 * scaleFactor),
                                child: Image.file(
                                  File(a['archivoPath']),
                                  height: 180 * scaleFactor,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  color: Colors.redAccent,
                                  size: 24 * scaleFactor),
                              onPressed: () => _eliminarAnotacion(a['id']),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormularioAnotacion(context, scaleFactor),
        backgroundColor: azulLensys,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28* scaleFactor),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _mostrarFormularioAnotacion(BuildContext context, double scaleFactor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scaleFactor)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16 * scaleFactor,
          right: 16 * scaleFactor,
          bottom: MediaQuery.of(context).viewInsets.bottom + (16 * scaleFactor),
          top: 24 * scaleFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nueva Anotación',
              style: TextStyle(fontSize: 18 * scaleFactor, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16 * scaleFactor),
            TextField(
              controller: _tituloController,
              style: TextStyle(fontSize: 14 * scaleFactor),
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle: TextStyle(fontSize: 14 * scaleFactor),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12 * scaleFactor),
            TextField(
              controller: _contenidoController,
              maxLines: 3,
              style: TextStyle(fontSize: 14 * scaleFactor),
              decoration: InputDecoration(
                labelText: 'Contenido (opcional)',
                labelStyle: TextStyle(fontSize: 14 * scaleFactor),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16 * scaleFactor),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.image, size: 18 * scaleFactor),
                    label: Text('Imagen', style: TextStyle(fontSize: 14 * scaleFactor)),
                    onPressed: _seleccionarArchivo,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulLensys,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 12 * scaleFactor,
                        horizontal: 16 * scaleFactor,
                      ),
                      textStyle: TextStyle(fontSize: 14 * scaleFactor),
                    ),
                  ),
                ),
                SizedBox(width: 12 * scaleFactor),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.save, size: 18 * scaleFactor),
                    label: Text('Guardar', style: TextStyle(fontSize: 14 * scaleFactor)),
                    onPressed: () => _agregarAnotacion(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: azulLensys,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: 12 * scaleFactor,
                        horizontal: 16 * scaleFactor,
                      ),
                      textStyle: TextStyle(fontSize: 14 * scaleFactor),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
