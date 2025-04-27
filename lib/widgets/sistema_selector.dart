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
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> sistemas = [];
  Set<int> seleccionados = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    cargarSistemas();
  }

  Future<void> cargarSistemas() async {
    final response = await supabase.from('sistemas_asociados').select();
    setState(() {
      sistemas = List<Map<String, dynamic>>.from(response);
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
      setState(() {
        sistemas.add(response);
        nuevoController.clear();
      });
    }
  }

  Future<void> eliminarSistema(int id) async {
    await supabase.from('sistemas_asociados').delete().eq('id', id);
    setState(() {
      sistemas.removeWhere((s) => s['id'] == id);
      seleccionados.remove(id);
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
    setState(() {
      final idx = sistemas.indexWhere((s) => s['id'] == id);
      sistemas[idx] = updated;
    });
  }

  void _notificarSeleccion() {
    final sel = sistemas.where((s) => seleccionados.contains(s['id'])).toList();
    widget.onSeleccionar(sel);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sistemas Asociados'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
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
                  // Lista compacta con selección múltiple y edición
                  Expanded(
                    child: ListView.separated(
                      itemCount: sistemas.length,
                      separatorBuilder: (_, __) => const Divider(height: 8),
                      itemBuilder: (context, i) {
                        final s = sistemas[i];
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

                  // Input y botón para agregar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: nuevoController,
                          decoration: const InputDecoration(
                            hintText: 'Nuevo sistema',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => agregarSistema(nuevoController.text),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text(
                          'Añadir',
                          style: TextStyle(color: Colors.white),
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
    return Row(
      children: [
        Checkbox(
          value: widget.isSelected,
          onChanged: widget.onSelect,
        ),
        Expanded(
          child: editing
              ? TextField(
                  controller: editController,
                  autofocus: true,
                  onSubmitted: (v) {
                    widget.onEdit(v);
                    setState(() => editing = false);
                  },
                )
              : GestureDetector(
                  onDoubleTap: () => setState(() => editing = true),
                  child: Text(
                    widget.sistema['nombre'],
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.edit, size: 18),
          onPressed: () => setState(() => editing = true),
          tooltip: 'Editar',
        ),
        IconButton(
          icon: const Icon(Icons.delete, size: 18, color: Colors.redAccent),
          onPressed: widget.onDelete,
          tooltip: 'Eliminar',
        ),
      ],
    );
  }
}
