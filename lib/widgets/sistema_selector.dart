import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SistemasScreen extends StatefulWidget {
  final void Function(List<Map<String, dynamic>> sistemas) onSeleccionar;

  const SistemasScreen({super.key, required this.onSeleccionar});

  @override
  State<SistemasScreen> createState() => _SistemasScreenState();
}

class _SistemasScreenState extends State<SistemasScreen> {
  final TextEditingController nuevoController = TextEditingController();
  final TextEditingController busquedaController = TextEditingController();
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> sistemas = [];
  List<Map<String, dynamic>> sistemasFiltrados = [];
  Set<int> seleccionados = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    busquedaController.addListener(_filtrarBusqueda);
    cargarSistemas();
  }

  @override
  void dispose() {
    nuevoController.dispose();
    busquedaController.dispose();
    super.dispose();
  }

  void _filtrarBusqueda() {
    final query = busquedaController.text.trim().toLowerCase();
    setState(() {
      sistemasFiltrados = query.isEmpty
          ? List.from(sistemas)
          : sistemas.where((s) => s['nombre'].toLowerCase().contains(query)).toList();
    });
  }

  Future<void> cargarSistemas() async {
    setState(() => isLoading = true);
    try {
      final response = await supabase.from('sistemas_asociados').select();
      final lista = List<Map<String, dynamic>>.from(response);
      lista.sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));

      setState(() {
        sistemas = lista;
        sistemasFiltrados = List.from(lista);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _mostrarError('Error al cargar: $e');
    }
  }

  Future<void> agregarSistema(String nombre) async {
    if (nombre.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final nuevo = await supabase
          .from('sistemas_asociados')
          .insert({'nombre': nombre})
          .select()
          .single();
      setState(() {
        sistemas.add(nuevo);
        sistemas.sort((a, b) => a['nombre'].toString().compareTo(b['nombre'].toString()));
        _filtrarBusqueda();
        nuevoController.clear();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _mostrarError('Error al agregar: $e');
    }
  }

  Future<void> eliminarSistema(int id) async {
    setState(() => isLoading = true);
    try {
      await supabase.from('sistemas_asociados').delete().eq('id', id);
      setState(() {
        sistemas.removeWhere((s) => s['id'] == id);
        seleccionados.remove(id);
        _filtrarBusqueda();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _mostrarError('Error al eliminar: $e');
    }
  }

  Future<void> editarSistema(int id, String nuevoNombre) async {
    if (nuevoNombre.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final actualizado = await supabase
          .from('sistemas_asociados')
          .update({'nombre': nuevoNombre})
          .eq('id', id)
          .select()
          .single();
      final idx = sistemas.indexWhere((s) => s['id'] == id);
      setState(() {
        sistemas[idx] = actualizado;
        _filtrarBusqueda();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      _mostrarError('Error al editar: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarDialogo(Map<String, dynamic> sistema) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(sistema['nombre']), // Modificado: Se elimina "Sistema: "
        content: const Text('¿Qué deseas hacer?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarEditarDialogo(sistema);
            },
            child: const Text('Editar'), // Modificado: Se quita el estilo explícito si lo tuviera, para usar el color por defecto.
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              eliminarSistema(sistema['id']);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarEditarDialogo(Map<String, dynamic> sistema) {
    final controller = TextEditingController(text: sistema['nombre']);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar sistema'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Nombre',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              final nombre = controller.text.trim();
              if (nombre.isNotEmpty) {
                Navigator.pop(context);
                editarSistema(sistema['id'], nombre);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _notificarSeleccion() {
    final seleccionadosMap = sistemas.where((s) => seleccionados.contains(s['id'])).toList();
    widget.onSeleccionar(seleccionadosMap);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect( // Envolver con ClipRRect
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10.0)), // Definir el radio para las esquinas superiores
      child: SizedBox(
        height: 380,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF003056),
            automaticallyImplyLeading: false,
            title: TextField(
              controller: busquedaController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Buscar sistema...',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search, color: Colors.white),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _notificarSeleccion,
              ),
            ],
          ),
          body: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: sistemasFiltrados.isEmpty
                          ? const Center(child: Text('No hay sistemas'))
                          : ListView.builder(
                              itemCount: sistemasFiltrados.length,
                              itemBuilder: (_, i) {
                                final sistema = sistemasFiltrados[i];
                                return Card(
                                  color: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  elevation: 3,
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: seleccionados.contains(sistema['id']),
                                      onChanged: (sel) {
                                        setState(() {
                                          if (sel == true) {
                                            seleccionados.add(sistema['id']);
                                          } else {
                                            seleccionados.remove(sistema['id']);
                                          }
                                        });
                                      },
                                    ),
                                    title: Text(
                                      sistema['nombre'],
                                      style: const TextStyle(color: Color(0xFF003056)),
                                    ),
                                    onTap: () => _mostrarDialogo(sistema),
                                  ),
                                );
                              },
                            ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nuevoController,
                            decoration: const InputDecoration(
                              hintText: 'Nuevo sistema',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (value) => agregarSistema(value.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => agregarSistema(nuevoController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF003056),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                          child: const Text('Añadir', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
            ],
          ),
        ),
      ),
    );
  }
}
