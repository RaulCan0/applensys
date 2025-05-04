// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/widgets/sistema_selector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/principio_json.dart';
import '../services/supabase_service.dart';

String obtenerNombreDimension(String dimensionId) {
  switch (dimensionId) {
    case '1':
      return 'Dimensión 1';
    case '2':
      return 'Dimensión 2';
    case '3':
      return 'Dimensión 3';
    default:
      return 'Dimensión 1';
  }
}

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
  State<ComportamientoEvaluacionScreen> createState() =>
      _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState
    extends State<ComportamientoEvaluacionScreen> {
  int calificacion = 3;
  final TextEditingController observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;

  void _mostrarLentesRolDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 150, vertical: 130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.90,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ScrollConfiguration(
            behavior: MaterialScrollBehavior().copyWith(
              dragDevices: const {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: SingleChildScrollView(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: _buildLentesDataTable(),
              ),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.end,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  DataTable _buildLentesDataTable() {
    return DataTable(
      columnSpacing: 9,
      dataRowMinHeight: 60,
      dataRowMaxHeight: 100,
      headingRowHeight: 50,
      headingTextStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      dataTextStyle: const TextStyle(fontSize: 10, color: Colors.black87),
      columns: const [
        DataColumn(label: Text('Lentes / Rol')),
        DataColumn(label: Text('Nivel 1\n0–20%')),
        DataColumn(label: Text('Nivel 2\n21–40%')),
        DataColumn(label: Text('Nivel 3\n41–60%')),
        DataColumn(label: Text('Nivel 4\n61–80%')),
        DataColumn(label: Text('Nivel 5\n81–100%')),
      ],
      rows: [
        DataRow(cells: [
          const DataCell(Text('Ejecutivos')),
          _wrapText(
              'Los ejecutivos se centran principalmente en la lucha contra incendios y en gran parte están ausentes de los esfuerzos de mejora.'),
          _wrapText(
              'Los ejecutivos son conscientes de las iniciativas de otros para mejorar, pero en gran parte no están involucrados.'),
          _wrapText(
              'Los ejecutivos establecen la dirección para la mejora y respaldan los esfuerzos de los demás.'),
          _wrapText(
              'Los ejecutivos participan en los esfuerzos de mejora y respaldan el alineamiento de los principios de excelencia operacional con los sistemas.'),
          _wrapText(
              'Los ejecutivos se centran en garantizar que los principios de excelencia operativa se arraiguen profundamente en la cultura y se evalúen regularmente para mejorar.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Gerentes')),
          _wrapText(
              'Los gerentes están orientados a obtener resultados "a toda costa".'),
          _wrapText(
              'Los gerentes generalmente buscan especialistas para crear mejoras a través de la orientación del proyecto.'),
          _wrapText(
              'Los gerentes participan en el desarrollo de sistemas y ayudan a otros a usar herramientas de manera efectiva.'),
          _wrapText(
              'Los gerentes se enfocan en conductas de manejo a través del diseño de sistemas.'),
          _wrapText(
              'Los gerentes están "principalmente enfocados" en la mejora continua de los sistemas para impulsar un comportamiento más alineado con los principios de excelencia operativa.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Miembros del equipo')),
          _wrapText(
              'Los miembros del equipo se enfocan en hacer su trabajo y son tratados en gran medida como un gasto.'),
          _wrapText(
              'A veces se solicita a los asociados que participen en un equipo de mejora usualmente dirigido por alguien externo a su equipo de trabajo natural.'),
          _wrapText('Están capacitados y participan en proyectos de mejora.'),
          _wrapText(
              'Están involucrados todos los días en el uso de herramientas para la mejora continua en sus propias áreas de responsabilidad.'),
          _wrapText(
              'Entienden los principios "el por qué" detrás de las herramientas y son líderes para mejorar sus propios sistemas y ayudar a otros.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Frecuencia')),
          _wrapText('Infrecuente • Raro'),
          _wrapText('Basado en eventos • Irregular'),
          _wrapText('Frecuente • Común'),
          _wrapText('Consistente • Predominante'),
          _wrapText('Constante • Uniforme'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Duración')),
          _wrapText('Iniciado • Subdesarrollado'),
          _wrapText('Experimental • Formativo'),
          _wrapText('Repetible • Previsible'),
          _wrapText('Establecido • Estable'),
          _wrapText('Culturalmente Arraigado • Maduro'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Intensidad')),
          _wrapText('Apático • Indiferente'),
          _wrapText('Aparente • Compromiso Individual'),
          _wrapText('Moderado • Compromiso Local'),
          _wrapText('Persistente • Amplio Compromiso'),
          _wrapText('Tenaz • Compromiso Total'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Alcance')),
          _wrapText('Aislado • Punto de Solución'),
          _wrapText('Silos • Flujo de Valor Interno'),
          _wrapText('Predominante‑mente Operaciones • Flujo de Valor Funcional'),
          _wrapText(
              'Múltiples Procesos de Negocios • Flujo de Valor Integrado'),
          _wrapText('En Toda la Empresa • Flujo de Valor Extendido'),
        ]),
      ],
    );
  }

  DataCell _wrapText(String text) {
    return DataCell(
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Text(
          text,
          softWrap: true,
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }


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
    final observacion = observacionController.text.trim();
    if (observacion.isEmpty || observacion.split(RegExp(r'\s+')).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Debes escribir una observación para guardar la evaluación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (sistemasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Debes seleccionar o crear al menos un sistema asociado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final supabase = SupabaseService();
      final comportamientoNombre =
          widget.principio.benchmarkComportamiento.split(':').first.trim();

      final calificacionObj = Calificacion(
        id: const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: int.tryParse(widget.dimensionId) ?? 1,
        comportamiento: comportamientoNombre,
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: observacion,
        sistemas: sistemasSeleccionados,
      );

      await supabase.addCalificacion(
        calificacionObj,
        id: widget.evaluacionId,
        idAsociado: widget.asociadoId,
      );

      TablasDimensionScreen.actualizarDato(
        widget.evaluacionId,
        dimension: obtenerNombreDimension(widget.dimensionId),
        principio: widget.principio.nombre,
        comportamiento: comportamientoNombre,
        cargo: widget.cargo,
        valor: calificacion,
        sistemas: sistemasSeleccionados,
      );

      if (mounted) Navigator.pop(context, comportamientoNombre);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  
  @override
  Widget build(BuildContext context) {
    final desc = widget.principio.calificaciones['C$calificacion'] ??
        'Sin descripción disponible';

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
                ElevatedButton.icon(
                  icon: const Icon(Icons.info_outline, size: 18),
                  label: const Text('Benchmark Nivel',
                      style: TextStyle(fontSize: 12)),
                  onPressed: () => _mostrarDialogo(
                      'Benchmark', widget.principio.benchmarkPorNivel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.help_outline, size: 18),
                  label:
                      const Text('Guía', style: TextStyle(fontSize: 12)),
                  onPressed: () =>
                      _mostrarDialogo('Guía', widget.principio.preguntas),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Sistemas',
                      style: TextStyle(fontSize: 12)),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final seleccionados =
                              await showModalBottomSheet<List<String>>(
                            context: context,
                            isScrollControlled: true,
                            builder: (c) => SistemasScreen(
                              onSeleccionar: (sistemas) {
                                Navigator.pop(
                                  c,
                                  sistemas
                                      .map((e) => e['nombre'].toString())
                                      .toList(),
                                );
                              },
                            ),
                          );
                          if (seleccionados != null) {
                            setState(() =>
                                sistemasSeleccionados = seleccionados);
                          }
                        },
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Benchmark:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(widget.principio.benchmarkComportamiento),
            const SizedBox(height: 16),
            const Text('Calificación:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: calificacion.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: calificacion.toString(),
              onChanged: isSaving
                  ? null
                  : (v) => setState(() => calificacion = v.round()),
            ),
            Text('Descripción ($calificacion):',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(desc),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.remove_red_eye),
              label: const Text('Ver lentes de madurez'),
              onPressed: _mostrarLentesRolDialog,
            ),
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
                IconButton(icon: const Icon(Icons.camera_alt, size: 28), onPressed: () {}),
              ],
            ),
            const SizedBox(height: 16),
            if (sistemasSeleccionados.isNotEmpty)
              Wrap(
                spacing: 6,
                children: sistemasSeleccionados.map((s) => Chip(
                  label: Text(s),
                  onDeleted: () => setState(() => sistemasSeleccionados.remove(s)),
                )).toList(),
              ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
                icon: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save, color: Colors.white),
                label: Text(
                isSaving ? 'Guardando...' : 'Guardar Evaluación',
                style: const TextStyle(color: Colors.white),
              ),
              onPressed: isSaving ? null : _guardarEvaluacion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.indigo,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
