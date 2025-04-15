import 'package:flutter/material.dart';
import 'package:applensys/widgets/sistema_selector.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart';

class ComportamientoEvaluacionScreen extends StatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
  });

  @override
  State<ComportamientoEvaluacionScreen> createState() =>
      _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState
    extends State<ComportamientoEvaluacionScreen> {
  int calificacion = 3;
  final TextEditingController observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];

  void _abrirSelectorSistemas() async {
    final seleccionados = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      builder:
          (_) =>
              SistemasSelectorWidget(onSeleccionar: (sistemasSeleccionados) {}),
    );

    if (seleccionados != null) {
      setState(() {
        sistemasSeleccionados = seleccionados;
      });
    }
  }

  void _guardarEvaluacion() {
    debugPrint("✅ Evaluación registrada ");
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final descripcionC =
        widget.principio.calificaciones['C$calificacion'] ??
        'Sin descripción disponible.';

    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar: ${widget.principio.nombre}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TablasDimensionScreen(),
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
            ElevatedButton(
              onPressed: () => _mostrarBenchmark(context),
              child: const Text('Ver benchmark por nivel'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _mostrarPreguntas(context),
              child: const Text('Ver preguntas guía'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Selecciona calificación (1 a 5):',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: calificacion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: calificacion.toString(),
              onChanged:
                  (value) => setState(() => calificacion = value.toInt()),
            ),
            Text('Descripción C$calificacion:'),
            Text(descripcionC),
            const SizedBox(height: 16),
            TextField(
              controller: observacionController,
              decoration: const InputDecoration(
                labelText: 'Observaciones',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Seleccionar sistemas asociados'),
              onPressed: _abrirSelectorSistemas,
            ),
            const SizedBox(height: 12),
            if (sistemasSeleccionados.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children:
                      sistemasSeleccionados
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Chip(
                                label: Text(s),
                                deleteIcon: const Icon(Icons.close),
                                onDeleted: () {
                                  setState(() {
                                    sistemasSeleccionados.remove(s);
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                ),
              ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text('Guardar evaluación'),
              onPressed: _guardarEvaluacion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarPreguntas(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Guía de preguntas'),
            content: Text(widget.principio.preguntas),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }

  void _mostrarBenchmark(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Benchmark por nivel'),
            content: Text(widget.principio.benchmarkPorNivel),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cerrar'),
              ),
            ],
          ),
    );
  }
}
