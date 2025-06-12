import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ShingoResultSheet extends StatefulWidget {
  const ShingoResultSheet({super.key});

  @override
  State<ShingoResultSheet> createState() => _ShingoResultSheetState();
}

class _ShingoResultSheetState extends State<ShingoResultSheet> {
  final Map<String, String> campos = {
    'Cómo se calcula': '',
    'Cómo se mide': '',
    'Por qué es importante': '',
    'Sistemas usados para mejorar': '',
    'Explicación de desviaciones': '',
    'Cambios en 3 años': '',
    'Cómo se definen metas': '',
  };

  File? imagen;
  int calificacion = 0;

  Future<void> editarCampo(String titulo) async {
    final controller = TextEditingController(text: campos[titulo] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text("Guardar")),
        ],
      ),
    );
    if (result != null) {
      setState(() => campos[titulo] = result);
    }
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo != null) {
      setState(() => imagen = File(archivo.path));
    }
  }

  Widget cajaEditable(String titulo) {
    return InkWell(
      onTap: () => editarCampo(titulo),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black),
          color: Colors.grey.shade100,
        ),
        child: Text(
          campos[titulo]!.isEmpty ? 'Tocar para escribir $titulo' : '${campos[titulo]}',
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }

  Widget calificacionWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return IconButton(
          icon: Icon(i < calificacion ? Icons.star : Icons.star_border, color: Colors.orange),
          onPressed: () => setState(() => calificacion = i + 1),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoja de Resultado')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: seleccionarImagen,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black),
                  color: Colors.grey.shade200,
                  image: imagen != null
                      ? DecorationImage(image: FileImage(imagen!), fit: BoxFit.cover)
                      : null,
                ),
                child: imagen == null
                    ? const Center(child: Text('Tocar para agregar imagen del gráfico'))
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            ...campos.keys.map(cajaEditable),
            const SizedBox(height: 20),
            const Text('Calificación (1-5)', style: TextStyle(fontSize: 16)),
            calificacionWidget(),
          ],
        ),
      ),
    );
  }
}
