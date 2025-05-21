// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/services/storage_service.dart';
import 'package:applensys/services/calificacion_service.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart';
import '../widgets/sistema_selector.dart';
import '../widgets/drawer_lensys.dart';
import '../providers/text_size_provider.dart';

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

class ComportamientoEvaluacionScreen extends ConsumerStatefulWidget {
  final PrincipioJson principio;
  final String cargo;
  final String evaluacionId;
  final String dimensionId;
  final String empresaId;
  final String asociadoId;

  const ComportamientoEvaluacionScreen({
    super.key,
    required this.principio,
    required this.cargo,
    required this.evaluacionId,
    required this.dimensionId,
    required this.empresaId,
    required this.asociadoId,
    required String dimension,
  });

  @override
  ConsumerState<ComportamientoEvaluacionScreen> createState() =>
      _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState
    extends ConsumerState<ComportamientoEvaluacionScreen> {
  final storageService = StorageService();
  final calificacionService = CalificacionService();
  final _picker = ImagePicker();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  int calificacion = 3;
  final observacionController = TextEditingController();
  List<String> sistemasSeleccionados = [];
  bool isSaving = false;
  String? evidenciaUrl;

  void _showAlert(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'))
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    final source = ImageSource.gallery;
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;
      final Uint8List bytes = await photo.readAsBytes();
      final String fileName = const Uuid().v4();

      await storageService.uploadFile(
        bucket: 'evidencias',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      evidenciaUrl =
          storageService.getPublicUrl(bucket: 'evidencias', path: fileName);
      setState(() {});
      _showAlert('Evidencia', 'Imagen subida correctamente.');
    } catch (e) {
      _showAlert('Error', 'No se pudo obtener la imagen: $e');
    }
  }

  Future<void> _guardarEvaluacion() async {
    final obs = observacionController.text.trim();
    if (obs.isEmpty) {
      _showAlert('Validación', 'Debes escribir una observación.');
      return;
    }
    if (sistemasSeleccionados.isEmpty) {
      _showAlert('Validación', 'Selecciona al menos un sistema.');
      return;
    }
    setState(() => isSaving = true);
    try {
      final nombreComp =
          widget.principio.benchmarkComportamiento.split(':').first.trim();
      final dimId = int.tryParse(widget.dimensionId) ?? 1;
      final existente = await calificacionService.getCalificacionExistente(
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: dimId,
        comportamiento: nombreComp,
      );
      if (existente != null) {
        final editar = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Modificar calificación'),
            content: const Text(
                'Ya existe una calificación para este comportamiento. ¿Deseas modificarla?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('No')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sí')),
            ],
          ),
        );
        if (editar == true) {
          final calObj = Calificacion(
            id: existente.id,
            idAsociado: widget.asociadoId,
            idEmpresa: widget.empresaId,
            idDimension: dimId,
            comportamiento: nombreComp,
            puntaje: calificacion,
            fechaEvaluacion: DateTime.now(),
            observaciones: obs,
            sistemas: sistemasSeleccionados,
            evidenciaUrl: evidenciaUrl,
          );
          await calificacionService.updateCalificacionFull(calObj);
          TablasDimensionScreen.actualizarDato(
            widget.evaluacionId,
            dimension: obtenerNombreDimension(widget.dimensionId),
            principio: widget.principio.nombre,
            comportamiento: nombreComp,
            cargo: widget.cargo,
            valor: calificacion,
            sistemas: sistemasSeleccionados,
            dimensionId: widget.dimensionId,
            asociadoId: widget.asociadoId,
          );
          if (mounted) Navigator.pop(context, nombreComp);
        }
        return;
      }
      final calObj = Calificacion(
        id: const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: dimId,
        comportamiento: nombreComp,
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: obs,
        sistemas: sistemasSeleccionados,
        evidenciaUrl: evidenciaUrl,
      );
      await calificacionService.addCalificacion(calObj);
      TablasDimensionScreen.actualizarDato(
        widget.evaluacionId,
        dimension: obtenerNombreDimension(widget.dimensionId),
        principio: widget.principio.nombre,
        comportamiento: nombreComp,
        cargo: widget.cargo,
        valor: calificacion,
        sistemas: sistemasSeleccionados,
        dimensionId: widget.dimensionId,
        asociadoId: widget.asociadoId,
      );
      if (mounted) Navigator.pop(context, nombreComp);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  DataTable _buildLentesDataTable() {
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = textSize / 14.0;

    DataCell wrapText(String text) => DataCell(
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 200 * scaleFactor),
            child: Text(text,
                softWrap: true,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11 * scaleFactor)),
          ),
        );

    return DataTable(
      columnSpacing: 9 * scaleFactor,
      dataRowMinHeight: 60 * scaleFactor,
      dataRowMaxHeight: 100 * scaleFactor,
      headingRowHeight: 50 * scaleFactor,
      headingTextStyle: TextStyle(
          fontSize: 12 * scaleFactor,
          fontWeight: FontWeight.bold,
          color: Colors.black),
      dataTextStyle:
          TextStyle(fontSize: 10 * scaleFactor, color: Colors.black87),
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
          wrapText(
              'Se centran en la lucha contra incendios y están ausentes de los esfuerzos de mejora.'),
          wrapText(
              'Son conscientes de iniciativas de mejora, pero no se involucran.'),
          wrapText(
              'Establecen dirección para la mejora y apoyan esfuerzos.'),
          wrapText(
              'Participan activamente y alinean principios con sistemas.'),
          wrapText(
              'Aseguran arraigo de principios en la cultura y evalúan regularmente.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Gerentes')),
          wrapText('Orientados a resultados "a toda costa".'),
          wrapText('Delegan mejoras a especialistas con guía externa.'),
          wrapText('Ayudan a usar herramientas y desarrollan sistemas.'),
          wrapText('Diseñan sistemas para moldear comportamientos.'),
          wrapText(
              'Enfocados en mejora continua para alinear sistemas con excelencia.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Miembros del equipo')),
          wrapText('Se enfocan en hacer su trabajo; tratados como gasto.'),
          wrapText(
              'Participan ocasionalmente en proyectos dirigidos externamente.'),
          wrapText('Capacitados y activos en proyectos de mejora.'),
          wrapText('Usan herramientas de mejora en su área.'),
          wrapText(
              'Líderes en mejora de sistemas propios y apoyo a otros.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Frecuencia')),
          wrapText('Infrecuente • Raro'),
          wrapText('Basado en eventos • Irregular'),
          wrapText('Frecuente • Común'),
          wrapText('Consistente • Predominante'),
          wrapText('Constante • Uniforme'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Duración')),
          wrapText('Iniciado • Subdesarrollado'),
          wrapText('Experimental • Formativo'),
          wrapText('Repetible • Previsible'),
          wrapText('Establecido • Estable'),
          wrapText('Culturalmente Arraigado • Maduro'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Intensidad')),
          wrapText('Apático • Indiferente'),
          wrapText('Aparente • Compromiso Individual'),
          wrapText('Moderado • Compromiso Local'),
          wrapText('Persistente • Amplio Compromiso'),
          wrapText('Tenaz • Compromiso Total'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Alcance')),
          wrapText('Aislado • Punto de Solución'),
          wrapText('Silos • Flujo de Valor Interno'),
          wrapText('Predominantemente Operaciones • Flujo de Valor Funcional'),
          wrapText('Múltiples Procesos • Flujo de Valor Integrado'),
          wrapText('Toda la Empresa • Flujo de Valor Extendido'),
        ]),
      ],
    );
  }

  void _mostrarLentesRolDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 150, vertical: 130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.90,
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: ScrollConfiguration(
            behavior: MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad
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
              child: const Text('Cerrar'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = textSize / 14.0;

    final desc =
        widget.principio.calificaciones['C$calificacion'] ?? 'Sin descripción disponible';
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
        centerTitle: true,
        title: Text('El principio: ${widget.principio.nombre}',
            style: TextStyle(color: Colors.white, fontSize: 20 * scaleFactor)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer())
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: Text('Benchmark Nivel',
                  style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: () =>
                  _showAlert('Benchmark', widget.principio.benchmarkPorNivel),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.help_outline, size: 18),
              label: Text('Guía', style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: () => _showAlert('Guía', widget.principio.preguntas),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: Text('Sistemas',
                  style: TextStyle(fontSize: 12 * scaleFactor)),
              onPressed: isSaving
                  ? null
                  : () async {
                      final sel = await showModalBottomSheet<List<String>>(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => SistemasScreen(
                          onSeleccionar: (s) {
                            Navigator.pop(
                                context,
                                s.map((e) => e['nombre'].toString())
                                    .toList());
                          },
                        ),
                      );
                      if (sel != null) setState(() => sistemasSeleccionados = sel);
                    },
            ),
          ]),
          const SizedBox(height: 20),
          if (evidenciaUrl != null)
            Image.network(evidenciaUrl!, height: 200 * scaleFactor),
          const SizedBox(height: 16),
          Text('Calificación:',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
          Slider(
            value: calificacion.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: calificacion.toString(),
            onChanged: isSaving ? null : (v) => setState(() => calificacion = v.round()),
          ),
          Text('Descripción ($calificacion):',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
          Text(desc, style: TextStyle(fontSize: 14 * scaleFactor)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.remove_red_eye),
            label: Text('Ver lentes de madurez',
                style: TextStyle(fontSize: 14 * scaleFactor)),
            onPressed: _mostrarLentesRolDialog,
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: TextField(
                controller: observacionController,
                maxLines: 2,
                enabled: !isSaving,
                decoration: const InputDecoration(
                    hintText: 'Observaciones...', border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
                icon: const Icon(Icons.camera_alt, size: 28),
                onPressed: isSaving ? null : _takePhoto),
          ]),
          if (sistemasSeleccionados.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('Sistemas Asociados:',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14 * scaleFactor)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: sistemasSeleccionados.map((sistema) {
                return Chip(
                  label: Text(sistema,
                      style: TextStyle(fontSize: 12 * scaleFactor)),
                  onDeleted: () =>
                      setState(() => sistemasSeleccionados.remove(sistema)),
                  deleteIcon: const Icon(Icons.close, size: 18),
                );
              }).toList(),
            ),
          ],
          if (evidenciaUrl != null) ...[
            const SizedBox(height: 16),
            Image.network(evidenciaUrl!,
                height: MediaQuery.of(context).size.height * 0.2 * scaleFactor),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: isSaving
                ? SizedBox(
                    width: 20 * scaleFactor,
                    height: 20 * scaleFactor,
                    child: const CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.save, color: Colors.white),
            label: Text(isSaving ? 'Guardando...' : 'Guardar Evaluación',
                style: TextStyle(color: Colors.white, fontSize: 16 * scaleFactor)),
            onPressed: isSaving ? null : _guardarEvaluacion,
            style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(50 * scaleFactor),
                backgroundColor: const Color.fromARGB(255, 35, 47, 112)),
          ),
        ]),
      ),
    );
  }
}