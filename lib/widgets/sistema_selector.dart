import 'package:flutter/material.dart';

class SistemasSelectorWidget extends StatefulWidget {
  const SistemasSelectorWidget({
    super.key,
    required Null Function(dynamic sistemasSeleccionados) onSeleccionar,
  });

  @override
  State<SistemasSelectorWidget> createState() => _SistemasSelectorWidgetState();
}

class _SistemasSelectorWidgetState extends State<SistemasSelectorWidget> {
  final TextEditingController nuevoSistemaController = TextEditingController();

  List<String> sistemas = [
    "Liderazgo",
    "Estándares",
    "Indicadores",
    "Procesos clave",
    "Seguridad",
    "Calidad",
    "Mejora continua",
    "Mantenimiento",
    "Desarrollo de personal",
    "Comunicación",
    "Evaluación",
    "Reconocimiento",
    "Capacitación",
    "Cultura",
    "Enfoque al cliente",
    "Tecnología",
  ];

  List<String> seleccionados = [];

  void agregarSistema() {
    final nuevo = nuevoSistemaController.text.trim();
    if (nuevo.isNotEmpty && !sistemas.contains(nuevo)) {
      setState(() {
        sistemas.add(nuevo);
        nuevoSistemaController.clear();
      });
    }
  }

  void eliminarSistema(String sistema) {
    setState(() {
      sistemas.remove(sistema);
      seleccionados.remove(sistema);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder:
          (_, controller) => Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Selecciona los sistemas relacionados:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Scrollbar(
                    controller: controller,
                    thumbVisibility: true,
                    child: ListView(
                      controller: controller,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              sistemas.map((sistema) {
                                final seleccionado = seleccionados.contains(
                                  sistema,
                                );
                                return InputChip(
                                  label: Text(
                                    sistema,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  selected: seleccionado,
                                  selectedColor: Colors.indigo.shade100,
                                  onSelected: (_) {
                                    setState(() {
                                      seleccionado
                                          ? seleccionados.remove(sistema)
                                          : seleccionados.add(sistema);
                                    });
                                  },
                                  onDeleted: () => eliminarSistema(sistema),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                );
                              }).toList(),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: nuevoSistemaController,
                          decoration: InputDecoration(
                            labelText: 'Agregar nuevo sistema',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: agregarSistema,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context, seleccionados);
                            },
                            icon: const Icon(Icons.check),
                            label: const Text("Guardar selección"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
