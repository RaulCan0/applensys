import 'package:applensys/models/calificacion.dart';
import 'package:applensys/widgets/sistema_selector.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/principio_json.dart';
import '../services/supabase_service.dart';

class ComportamientoEvaluacionScreen extends StatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;
  final String empresaId;
  final String asociadoId;
  final String dimension;

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
    required this.empresaId,
    required this.asociadoId,
    required this.dimension,
  });

  @override
  State<ComportamientoEvaluacionScreen> createState() => _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState extends State<ComportamientoEvaluacionScreen> {
  int calificacion = 3;
  final TextEditingController observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;

  void _mostrarDialogo(String titulo, String contenido) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(contenido.isNotEmpty ? contenido : 'No disponible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarEvaluacion() async {
    setState(() => isSaving = true);
    try {
      final supabase = SupabaseService();
      final comportamientoNombre = widget.principio.benchmarkComportamiento.split(":").first.trim();

      final calificacionObj = Calificacion(
        id: const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: int.tryParse(widget.dimensionId) ?? 1,
        comportamiento: comportamientoNombre,
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: observacionController.text,
      );

      await supabase.addCalificacion(calificacionObj, id: '', idAsociado: '');

      if (mounted) {
        Navigator.pop(context, comportamientoNombre);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final descripcionActual = widget.principio.calificaciones['C$calificacion'] ?? 'Sin descripción disponible';

    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluar: ${widget.principio.nombre}'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Benchmark Nivel', style: TextStyle(fontSize: 12)),
                    onPressed: () => _mostrarDialogo('Benchmark por Nivel', widget.principio.benchmarkPorNivel),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.help_outline, size: 18),
                    label: const Text('Guía', style: TextStyle(fontSize: 12)),
                    onPressed: () => _mostrarDialogo('Preguntas Guía', widget.principio.preguntas),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.settings, size: 18),
                    label: const Text('Sistemas', style: TextStyle(fontSize: 12)),
                    onPressed: isSaving ? null : () async {
                      final seleccionados = await showModalBottomSheet<List<String>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => SistemasScreen(
                          onSeleccionar: (List<Map<String, dynamic>> sistemas) {
                            Navigator.pop(context, sistemas.map((s) => s['nombre'].toString()).toList());
                          },
                        ),
                      );
                      if (seleccionados != null) {
                        setState(() {
                          sistemasSeleccionados = seleccionados;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Benchmark:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(widget.principio.benchmarkComportamiento, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            const Text('Calificación:', style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: calificacion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: calificacion.toString(),
              onChanged: isSaving ? null : (value) => setState(() => calificacion = value.round()),
            ),
            Text('Descripción ($calificacion):', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(descripcionActual),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: observacionController,
                    maxLines: 2,
                    enabled: !isSaving,
                    decoration: const InputDecoration(
                      hintText: 'Observaciones...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.camera_alt, size: 28),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (sistemasSeleccionados.isNotEmpty)
              Wrap(
                spacing: 6,
                children: sistemasSeleccionados
                    .map((sistema) => Chip(
                          label: Text(sistema),
                          onDeleted: () => setState(() => sistemasSeleccionados.remove(sistema)),
                        ))
                    .toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
                label: Text(
                isSaving ? 'Guardando...' : 'Guardar Evaluación',
                style: const TextStyle(color: Colors.white),
                ),
              onPressed: isSaving ? null : _guardarEvaluacion,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }
}
