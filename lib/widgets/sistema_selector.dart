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
    cargarSistemas();
    busquedaController.addListener(_filtrarBusqueda);
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
    final response = await supabase.from('sistemas_asociados').select();
    if (!mounted) return;
    setState(() {
      sistemas = List<Map<String, dynamic>>.from(response);
      sistemasFiltrados = List.from(sistemas);
      isLoading = false;
    });
  }

  Future<void> agregarSistema(String nombre) async {
    if (nombre.isNotEmpty) {
      final response = await supabase
          .from('sistemas_asociados')
          .insert({'nombre': nombre})
          .select()
          .single();
      if (!mounted) return;
      setState(() {
        sistemas.add(response);
        nuevoController.clear();
        _filtrarBusqueda();
      });
    }
  }

  Future<void> eliminarSistema(int id) async {
    await supabase.from('sistemas_asociados').delete().eq('id', id);
    if (!mounted) return;
    setState(() {
      sistemas.removeWhere((s) => s['id'] == id);
      seleccionados.remove(id);
      _filtrarBusqueda();
    });
  }

  Future<void> editarSistema(int id, String nuevoNombre) async {
    if (nuevoNombre.isEmpty) return;
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
      _filtrarBusqueda();
    });
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
          backgroundColor: Colors.indigo,
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
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  children: [
                    Expanded(
                      child: sistemasFiltrados.isEmpty
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
                                  onDelete: () => eliminarSistema(s['id']),
                                  onEdit: (nuevo) => editarSistema(s['id'], nuevo),
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
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => agregarSistema(nuevoController.text.trim()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
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
      ),
    );
  }
}

class _SistemaTile extends StatefulWidget {
  final Map<String, dynamic> sistema;
  final bool isSelected;
  final ValueChanged<bool?> onSelect;
  final VoidCallback onDelete;
  final ValueChanged<String> onEdit;

  const _SistemaTile({
    required this.sistema,
    required this.isSelected,
    required this.onSelect,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_SistemaTile> createState() => __SistemaTileState();
}

class __SistemaTileState extends State<_SistemaTile> {
  bool editing = false;
  late TextEditingController editController;

  @override
  void initState() {
    super.initState();
    editController = TextEditingController(text: widget.sistema['nombre']);
  }

  @override
  void dispose() {
    editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: widget.isSelected,
        onChanged: widget.onSelect,
        visualDensity: VisualDensity.compact,
      ),
      title: editing
          ? TextField(
              controller: editController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 4),
              ),
              onSubmitted: (v) {
                widget.onEdit(v.trim());
                setState(() => editing = false);
              },
              onTapOutside: (_) {
                if (editing && editController.text.trim() == widget.sistema['nombre']) {
                  setState(() => editing = false);
                }
              },
            )
          : GestureDetector(
              onDoubleTap: () => setState(() => editing = true),
              child: Text(widget.sistema['nombre'], style: const TextStyle(fontSize: 14)),
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(editing ? Icons.done : Icons.edit, size: 20),
            onPressed: () {
              if (editing) {
                widget.onEdit(editController.text.trim());
              }
              setState(() => editing = !editing);
            },
            tooltip: editing ? 'Guardar' : 'Editar',
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
            onPressed: widget.onDelete,
            tooltip: 'Eliminar',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
