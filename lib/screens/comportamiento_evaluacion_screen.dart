import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:applensys/models/calificacion.dart';
import 'package:applensys/services/supabase_service.dart';
import '../models/principio_json.dart';
import '../screens/tablas_screen.dart';
import '../widgets/sistema_selector.dart';
import '../widgets/drawer_lensys.dart';

String obtenerNombreDimension(String dimensionId) {
  switch (dimensionId) {
    case '1': return 'Dimensión 1';
    case '2': return 'Dimensión 2';
    case '3': return 'Dimensión 3';
    default: return 'Dimensión 1';
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
  // ignore: library_private_types_in_public_api
  _ComportamientoEvaluacionScreenState createState() => _ComportamientoEvaluacionScreenState();
}

class _ComportamientoEvaluacionScreenState extends State<ComportamientoEvaluacionScreen> {
  final _supabase = SupabaseService();
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
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))
        ],
      ),
    );
  }

  Future<void> _takePhoto() async {
    // En Windows la cámara no está soportada; usar galería como fallback
    final source = Platform.isWindows ? ImageSource.gallery : ImageSource.camera;
    try {
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo == null) return;
      final Uint8List bytes = await photo.readAsBytes();
      final String fileName = const Uuid().v4();

      await _supabase.uploadFile(
        bucket: 'evidencias',
        path: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );
      evidenciaUrl = _supabase.getPublicUrl(bucket: 'evidencias', path: fileName);
      setState(() {});
      _showAlert('Evidencia', 'Imagen subida correctamente.');
    } catch (e) {
      _showAlert('Error', 'No se pudo obtener la imagen: \$e');
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
      final nombreComp = widget.principio.benchmarkComportamiento.split(':').first.trim();
      final cal = Calificacion(
        id: const Uuid().v4(),
        idAsociado: widget.asociadoId,
        idEmpresa: widget.empresaId,
        idDimension: int.tryParse(widget.dimensionId) ?? 1,
        comportamiento: nombreComp,
        puntaje: calificacion,
        fechaEvaluacion: DateTime.now(),
        observaciones: obs,
        sistemas: sistemasSeleccionados,
        evidenciaUrl: evidenciaUrl,
      );
      await _supabase.addCalificacion(cal, id: widget.evaluacionId, idAsociado: widget.asociadoId);
      TablasDimensionScreen.actualizarDato(
        widget.evaluacionId,
        dimension: obtenerNombreDimension(widget.dimensionId),
        principio: widget.principio.nombre,
        comportamiento: nombreComp,
        cargo: widget.cargo,
        valor: calificacion,
        sistemas: sistemasSeleccionados,
      );
      // ignore: use_build_context_synchronously
      Navigator.pop(context, nombreComp);
    } catch (e) {
      _showAlert('Error', 'No se pudo guardar: \$e');
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  DataTable _buildLentesDataTable() {
    DataCell wrapText(String text) => DataCell(
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(text, softWrap: true, maxLines: 6, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
          ),
        );

    return DataTable(
      columnSpacing: 9,
      dataRowMinHeight: 60,
      dataRowMaxHeight: 100,
      headingRowHeight: 50,
      headingTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black),
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
          wrapText('Los ejecutivos se centran principalmente en la lucha contra incendios y en gran parte están ausentes de los esfuerzos de mejora.'),
          wrapText('Los ejecutivos son conscientes de las iniciativas de otros para mejorar, pero en gran parte no están involucrados.'),
          wrapText('Los ejecutivos establecen la dirección para la mejora y respaldan los esfuerzos de los demás.'),
          wrapText('Los ejecutivos participan en los esfuerzos de mejora y respaldan el alineamiento de los principios de excelencia operacional con los sistemas.'),
          wrapText('Los ejecutivos se centran en garantizar que los principios de excelencia operativa se arraiguen profundamente en la cultura y se evalúen regularmente para mejorar.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Gerentes')),
          wrapText('Los gerentes están orientados a obtener resultados "a toda costa".'),
          wrapText('Los gerentes generalmente buscan especialistas para crear mejoras a través de la orientación del proyecto.'),
          wrapText('Los gerentes participan en el desarrollo de sistemas y ayudan a otros a usar herramientas de manera efectiva.'),
          wrapText('Los gerentes se enfocan en conductas de manejo a través del diseño de sistemas.'),
          wrapText('Los gerentes están "principalmente enfocados" en la mejora continua de los sistemas para impulsar un comportamiento más alineado con los principios de excelencia operativa.'),
        ]),
        DataRow(cells: [
          const DataCell(Text('Miembros del equipo')),
          wrapText('Los miembros del equipo se enfocan en hacer su trabajo y son tratados en gran medida como un gasto.'),
          wrapText('A veces se solicita a los asociados que participen en un equipo de mejora usualmente dirigido por alguien externo a su equipo de trabajo natural.'),
          wrapText('Están capacitados y participan en proyectos de mejora.'),
          wrapText('Están involucrados todos los días en el uso de herramientas para la mejora continua en sus propias áreas de responsabilidad.'),
          wrapText('Entienden los principios "el por qué" detrás de las herramientas y son líderes para mejorar sus propios sistemas y ayudar a otros.'),
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
          wrapText('Múltiples Procesos de Negocios • Flujo de Valor Integrado'),
          wrapText('En Toda la Empresa • Flujo de Valor Extendido'),
        ]),
      ],
    );
  }

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
              dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
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
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desc = widget.principio.calificaciones['C\$calificacion'] ?? 'Sin descripción disponible';
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const DrawerLensys(),
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        title: Text('El principio:${widget.principio.nombre}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [IconButton(icon: const Icon(Icons.menu), onPressed: () => _scaffoldKey.currentState?.openEndDrawer())],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('Benchmark Nivel', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAlert('Benchmark', widget.principio.benchmarkPorNivel),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Guía', style: TextStyle(fontSize: 12)),
              onPressed: () => _showAlert('Guía', widget.principio.preguntas),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings, size: 18),
              label: const Text('Sistemas', style: TextStyle(fontSize: 12)),
              onPressed: isSaving
                  ? null
                  : () async {
                      final sel = await showModalBottomSheet<List<String>>(context: context, isScrollControlled: true, builder: (_) => SistemasScreen(onSeleccionar: (s) {
                        Navigator.pop(context, s.map((e) => e['nombre'].toString()).toList());
                      }));
                      if (sel != null) setState(() => sistemasSeleccionados = sel);
                    },
            ),
          ]),
          const SizedBox(height: 16),
          const Text('Benchmark:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(widget.principio.benchmarkComportamiento),
          const SizedBox(height: 16),
          const Text('Calificación:', style: TextStyle(fontWeight: FontWeight.bold)),
          Slider(value: calificacion.toDouble(), min: 1, max: 5, divisions: 4, label: calificacion.toString(), onChanged: isSaving ? null : (v) => setState(() => calificacion = v.round())),
            Text('Descripción ($calificacion):', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(widget.principio.calificaciones['C$calificacion'] ?? 'Sin descripción disponible'),
          Text(desc),
          const SizedBox(height: 16),
          ElevatedButton.icon(icon: const Icon(Icons.remove_red_eye), label: const Text('Ver lentes de madurez'), onPressed: _mostrarLentesRolDialog),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: observacionController, maxLines: 2, enabled: !isSaving, decoration: const InputDecoration(hintText: 'Observaciones...', border: OutlineInputBorder()))),
            const SizedBox(width: 8),
            IconButton(icon: const Icon(Icons.camera_alt, size: 28), onPressed: isSaving ? null : _takePhoto),
          ]),
          if (evidenciaUrl != null) ...[
            const SizedBox(height: 16),
            Image.network(evidenciaUrl!, height: MediaQuery.of(context).size.height * 0.2),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, color: Colors.white),
            label: Text(isSaving ? 'Guardando...' : 'Guardar Evaluación', style: const TextStyle(color: Colors.white)),
            onPressed: isSaving ? null : _guardarEvaluacion,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.indigo),
          ),
        ]),
      ),
    );
  }
}
