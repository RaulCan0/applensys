import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

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

  late Timer _refreshTimer;
  List<Map<String, dynamic>> sistemas = [];
  List<Map<String, dynamic>> sistemasFiltrados = [];
  Set<int> seleccionados = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarSistemas();
    busquedaController.addListener(_filtrarBusqueda);

    // Configurar un temporizador para actualizar los sistemas cada 30 segundos
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      cargarSistemas();
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
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
      _ordenarAlfabeticamente(sistemasFiltrados);
    });
  }

  void _ordenarAlfabeticamente(List<Map<String, dynamic>> lista) {
    lista.sort((a, b) => a['nombre'].toString().toLowerCase().compareTo(b['nombre'].toString().toLowerCase()));
  }

  Future<void> cargarSistemas() async {
    try {
      final response = await supabase.from('sistemas_asociados').select();
      if (!mounted) return;

      final sistemas = List<Map<String, dynamic>>.from(response);
      _ordenarAlfabeticamente(sistemas);

      setState(() {
        this.sistemas = sistemas;
        sistemasFiltrados = List.from(sistemas);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
      _mostrarError('Error al cargar sistemas: $e');
    }
  }

  Future<void> agregarSistema(String nombre) async {
    if (nombre.isEmpty) {
      _mostrarError('El nombre no puede estar vacío');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await supabase
          .from('sistemas_asociados')
          .insert({'nombre': nombre})
          .select()
          .single();

      if (!mounted) return;

      setState(() {
        sistemas.add(response);
        _ordenarAlfabeticamente(sistemas);
        nuevoController.clear();
        _filtrarBusqueda();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _mostrarError('Error al agregar sistema: $e');
    }
  }

  Future<void> eliminarSistema(int id) async {
    setState(() => isLoading = true);
    try {
      await supabase.from('sistemas_asociados').delete().eq('id', id);
      if (!mounted) return;

      setState(() {
        sistemas.removeWhere((s) => s['id'] == id);
        seleccionados.remove(id);
        _filtrarBusqueda();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _mostrarError('Error al eliminar sistema: $e');
    }
  }

  Future<void> editarSistema(int id, String nuevoNombre) async {
    if (nuevoNombre.isEmpty) {
      _mostrarError('El nombre no puede estar vacío');
      return;
    }

    setState(() => isLoading = true);
    try {
      final updated = await supabase
          .from('sistemas_asociados')
          .update({'nombre': nuevoNombre})
          .eq('id', id)
          .select()
          .single();

      if (!mounted) return;

      setState(() {
        final idx = sistemas.indexWhere((s) => s['id'] == id);
        if (idx != -1) sistemas[idx] = updated;
        _ordenarAlfabeticamente(sistemas);
        _filtrarBusqueda();
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _mostrarError('Error al editar sistema: $e');
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  void _mostrarDialogo(Map<String, dynamic> sistema) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sistema: ${sistema['nombre']}'),
        content: const Text('¿Qué acción deseas realizar?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoEditar(sistema);
            },
            child: const Text('Editar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mostrarDialogoConfirmarEliminar(sistema);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(Map<String, dynamic> sistema) {
    final editController = TextEditingController(text: sistema['nombre']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar sistema'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final texto = editController.text.trim();
              if (texto.isNotEmpty) {
                Navigator.pop(context);
                editarSistema(sistema['id'], texto);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ).then((_) => editController.dispose());
  }

  void _mostrarDialogoConfirmarEliminar(Map<String, dynamic> sistema) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${sistema['nombre']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
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

  void _notificarSeleccion() {
    final sel = sistemas.where((s) => seleccionados.contains(s['id'])).toList();
    widget.onSeleccionar(sel);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 380.0,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 35, 47, 112),
          automaticallyImplyLeading: false,
          elevation: 0,
          title: TextField(
            controller: busquedaController,
            style: const TextStyle(color: Colors.white),
            cursorColor: Colors.white,
            decoration: const InputDecoration(
              hintText: 'Buscar sistema...',
              hintStyle: TextStyle(color: Colors.white70),
              prefixIcon: Icon(Icons.search, color: Colors.white),
              border: InputBorder.none,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check, color: Colors.white),
              onPressed: _notificarSeleccion,
              tooltip: 'Confirmar selección',
            ),
          ],
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Expanded(
                    child: sistemasFiltrados.isEmpty && !isLoading
                        ? const Center(child: Text('No hay sistemas. Añade uno nuevo.'))
                        : ListView.separated(
                            itemCount: sistemasFiltrados.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final s = sistemasFiltrados[i];
                              return _SistemaTile(
                                sistema: s,
                                isSelected: seleccionados.contains(s['id']),
                                onSelect: (sel) {
                                  setState(() {
                                    sel == true
                                        ? seleccionados.add(s['id'])
                                        : seleccionados.remove(s['id']);
                                  });
                                },
                                onTap: () => _mostrarDialogo(s),
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nuevoController,
                            decoration: const InputDecoration(
                              hintText: 'Nuevo sistema',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (texto) => agregarSistema(texto.trim()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => agregarSistema(nuevoController.text.trim()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(255, 35, 47, 112),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Añadir', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (isLoading)
              Container(
                color: Colors.black12,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SistemaTile extends StatelessWidget {
  final Map<String, dynamic> sistema;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onTap;

  const _SistemaTile({
    required this.sistema,
    required this.isSelected,
    required this.onSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: isSelected,
        onChanged: onSelect,
        visualDensity: VisualDensity.compact,
      ),
      title: Text(
        sistema['nombre'],
        style: const TextStyle(fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}