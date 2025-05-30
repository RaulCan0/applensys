// lib/screens/anotaciones_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:applensys/services/domain/anotaciones_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:applensys/providers/text_size_provider.dart';

// StreamProvider a nivel de módulo
final anotacionesProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => AnotacionesService().streamAnotaciones(),
);

class AnotacionesScreen extends ConsumerStatefulWidget {
  final String userId;
  const AnotacionesScreen({super.key, required this.userId});

  @override
  ConsumerState<AnotacionesScreen> createState() => _AnotacionesScreenState();
}

class _AnotacionesScreenState extends ConsumerState<AnotacionesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _picker = ImagePicker();
  final _tituloController = TextEditingController();
  final _contenidoController = TextEditingController();

  // *** Define aquí tus categorías ***
  final List<String> _categories = [
    'Todas',
    'Trabajo',
    'Personal',
    'Ideas',
    'Proyectos',
  ];

  @override
  void initState() {
    super.initState();
    // IMPORTANT: length debe ser _categories.length
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tituloController.dispose();
    _contenidoController.dispose();
    super.dispose();
  }

  Future<void> _agregarAnotacion({String? archivoPath}) async {
    final titulo = _tituloController.text.trim();
    final contenido = _contenidoController.text.trim();
    final categoria = _categories[_tabController.index];

    if (titulo.isEmpty) {
      _mostrarError('El título es obligatorio.');
      return;
    }

    try {
      await AnotacionesService().agregarAnotacion(
        titulo: titulo,
        contenido: contenido.isNotEmpty ? contenido : null,
        archivoPath: archivoPath,
        categoria: categoria,
      );
      _tituloController.clear();
      _contenidoController.clear();
      Navigator.pop(context);
    } catch (e) {
      _mostrarError('Error al agregar la anotación: $e');
    }
  }

  Future<void> _seleccionarImagen() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      await _agregarAnotacion(archivoPath: file.path);
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _mostrarFormulario(double scale) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24 * scale)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16 * scale,
          right: 16 * scale,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16 * scale,
          top: 24 * scale,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nueva Página',
              style: TextStyle(
                fontSize: 18 * scale,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 16 * scale),
            TextField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título',
                labelStyle:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12 * scale),
            TextField(
              controller: _contenidoController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Contenido (opcional)',
                labelStyle:
                    TextStyle(color: Theme.of(context).colorScheme.onSurface),
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16 * scale),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    FluentIcons.image_20_regular,
                    size: 24 * scale,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _seleccionarImagen,
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _agregarAnotacion(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text('Guardar', style: TextStyle(fontSize: 14 * scale)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final scale = textSize / 14.0;
    final anotacionesAsync = ref.watch(anotacionesProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Text('Mis Libretas', style: TextStyle(fontSize: 20 * scale)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.onPrimary,
          tabs: _categories
              .map((c) => Tab(child: Text(c, style: TextStyle(fontSize: 14 * scale))))
              .toList(),
        ),
      ),
      body: anotacionesAsync.when(
        error: (e, _) => Center(
          child: Text('Error: $e', style: TextStyle(fontSize: 16 * scale)),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        data: (anotaciones) {
          return TabBarView(
            controller: _tabController,
            children: _categories.map((cat) {
              final notas = cat == 'Todas'
                  ? anotaciones
                  : anotaciones.where((n) => n['categoria'] == cat).toList();

              if (notas.isEmpty) {
                return Center(
                  child: Text('Sin páginas en "$cat"',
                      style: TextStyle(fontSize: 16 * scale)),
                );
              }

              return Padding(
                padding: EdgeInsets.all(12 * scale),
                child: GridView.builder(
                  itemCount: notas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12 * scale,
                    mainAxisSpacing: 12 * scale,
                    childAspectRatio: 3 / 4,
                  ),
                  itemBuilder: (context, i) {
                    final nota = notas[i];
                    return GestureDetector(
                      onTap: () {
                        // Navegación a detalle si lo necesitas
                      },
                      child: Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12 * scale),
                        ),
                        elevation: 2,
                        child: Padding(
                          padding: EdgeInsets.all(12 * scale),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nota['titulo'],
                                  style: TextStyle(
                                    fontSize: 16 * scale,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  )),
                              SizedBox(height: 8 * scale),
                              if (nota['contenido'] != null &&
                                  nota['contenido'].isNotEmpty)
                                Expanded(
                                  child: Text(
                                    nota['contenido'],
                                    maxLines: 6,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12 * scale,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              if (nota['archivoPath'] != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8 * scale),
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(8 * scale),
                                    child: Image.file(
                                      File(nota['archivoPath']),
                                      fit: BoxFit.cover,
                                      height: 60 * scale,
                                      width: double.infinity,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(scale),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(FluentIcons.note_add_20_regular,
            color: Theme.of(context).colorScheme.onPrimary),
      ),
    );
  }
}
