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
    'Título del Métrico': '',
    'Cómo se calcula': '',
    'Cómo se mide': '',
    'Por qué es importante': '',
    'Sistemas usados para mejorar': '',
    'Explicación de desviaciones': '',
    'Cambios en la medición': '',
    'Cómo se definen metas': '',
  };

  File? imagenGrafico;
  int calificacion = 0;

  Future<void> editarCampo(String titulo) async {
    final controller = TextEditingController(text: campos[titulo] ?? '');
    final resultado = await showDialog<String>(
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
    if (resultado != null) {
      setState(() => campos[titulo] = resultado);
    }
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final archivo = await picker.pickImage(source: ImageSource.gallery);
    if (archivo != null) {
      setState(() {
        imagenGrafico = File(archivo.path);
      });
    }
  }

  Widget campoEditable(String titulo) {
    return GestureDetector(
      onTap: () => editarCampo(titulo),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black26),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          campos[titulo]!.isEmpty ? "Tocar para editar: $titulo" : "$titulo:\n${campos[titulo]}",
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
      appBar: AppBar(title: const Text("Hoja de Resultado")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sección: Calidad | Métrica: First Pass Yield", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Página 9 de 12", style: TextStyle(fontSize: 12)),

            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    image: imagenGrafico != null
                        ? DecorationImage(image: FileImage(imagenGrafico!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: imagenGrafico == null
                      ? const Center(child: Text("Tocar para insertar imagen del gráfico"))
                      : null,
                ),
                Positioned.fill(
                  child: Material(color: Colors.transparent, child: InkWell(onTap: seleccionarImagen)),
                ),
              ],
            ),

            const SizedBox(height: 16),
            ...campos.keys.map(campoEditable),
            const SizedBox(height: 20),
            const Center(child: Text("Calificación (1 a 5)", style: TextStyle(fontSize: 16))),
            calificacionWidget(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
