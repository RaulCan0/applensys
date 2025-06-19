// lib/screens/shingo_result_screen.dart

import 'dart:io';
import 'package:applensys/services/shingo_result_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Lista de etiquetas por hoja
const List<String> sheetLabels = [
  'seguridad/medio ambiente/moral',
  'satisfacción del cliente',
  'calidad',
  'costo/productividad',
  'entregas',
];

/// Modelo para guardar los datos de cada hoja
class ShingoResultData {
  Map<String, String> campos;
  File? imagen;
  int calificacion;

  ShingoResultData({
    Map<String, String>? campos,
    this.imagen,
    this.calificacion = 0,
  }) : campos = campos ?? {
          'Cómo se calcula': '',
          'Cómo se mide': '',
          'Por qué es importante': '',
          'Sistemas usados para mejorar': '',
          'Explicación de desviaciones': '',
          'Cambios en 3 años': '',
          'Cómo se definen metas': '',
        };
}

/// Pantalla principal con los 5 botones grises
class ShingoResultsScreen extends StatefulWidget {
  const ShingoResultsScreen({super.key});

  @override
  State<ShingoResultsScreen> createState() => _ShingoResultsScreenState();
}

class _ShingoResultsScreenState extends State<ShingoResultsScreen> {
  final Map<String, ShingoResultData> hojasGuardadas = {
    for (var label in sheetLabels) label: ShingoResultData(),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shingo Prize – Resultados')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: sheetLabels.map((label) {
            return GestureDetector(
              onTap: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ShingoResultSheet(
                      title: label,
                      initialData: hojasGuardadas[label]!,
                    ),
                  ),
                );
                if (resultado != null && resultado is ShingoResultData) {
                  setState(() {
                    hojasGuardadas[label] = resultado;
                    ShingoResultService().guardarResultado(label, resultado);
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 200,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Hoja editable
class ShingoResultSheet extends StatefulWidget {
  final String title;
  final ShingoResultData initialData;

  const ShingoResultSheet({
    super.key,
    required this.title,
    required this.initialData,
  });

  @override
  State<ShingoResultSheet> createState() => _ShingoResultSheetState();
}

class _ShingoResultSheetState extends State<ShingoResultSheet> {
  late Map<String, String> campos;
  File? imagen;
  int calificacion = 0;

  @override
  void initState() {
    super.initState();
    campos = Map.from(widget.initialData.campos);
    imagen = widget.initialData.imagen;
    calificacion = widget.initialData.calificacion;
  }

  Future<void> editarCampo(String titulo) async {
    final controller = TextEditingController(text: campos[titulo] ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: TextField(controller: controller, maxLines: 4),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Guardar')),
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

  Widget calificacionWidget() => Row(
        children: [
          const Text('1'),
          Expanded(
            child: Slider(
              value: calificacion.toDouble(),
              min: 0.0,
              max: 5.0,
              divisions: 4,
              label: calificacion.toString(),
              onChanged: (value) {
                setState(() {
                  calificacion = value.round();
                });
              },
            ),
          ),
          const Text('5'),
        ],
      );

  Widget buildSeccion(String titulo, [String? valorPorDefecto]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => editarCampo(titulo),
          child: Container(
            padding: const EdgeInsets.all(10),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              color: Colors.grey.shade100,
            ),
            child: Text(
              campos[titulo]?.isEmpty ?? true
                  ? (valorPorDefecto ?? 'Tocar para escribir...')
                  : campos[titulo]!,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              Navigator.pop(
                context,
                ShingoResultData(
                  campos: campos,
                  imagen: imagen,
                  calificacion: calificacion,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 12),
            ...campos.keys.map(buildSeccion),
            const SizedBox(height: 16),
            const Center(child: Text('Calificación (1-5)', style: TextStyle(fontSize: 16))),
            calificacionWidget(),
          ],
        ),
      ),
    );
  }
}
