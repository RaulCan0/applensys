// ignore_for_file: use_build_context_synchronously

import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/principio_json.dart';
import 'package:applensys/screens/tablas_screen.dart' as tablas_screen;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import '../services/domain/json_service.dart';
import '../services/remote/supabase_service.dart';
import 'comportamiento_evaluacion_screen.dart';

class PrincipiosScreen extends StatefulWidget {
  final Empresa empresa;
  final Asociado asociado;
  final String dimensionId;

  const PrincipiosScreen({
    super.key,
    required this.empresa,
    required this.asociado,
    required this.dimensionId,
  });

  @override
  State<PrincipiosScreen> createState() => _PrincipiosScreenState();
}

class _PrincipiosScreenState extends State<PrincipiosScreen> {
  Map<String, List<PrincipioJson>> principiosUnicos = {};
  List<String> comportamientosEvaluados = [];
  bool cargando = true;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    cargarPrincipios();
    cargarComportamientosEvaluados();
  }

  Future<void> cargarPrincipios() async {
    try {
      final List<dynamic> datos = await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datos.isEmpty) throw Exception('El archivo JSON está vacío.');

      final todos = datos.map((e) => PrincipioJson.fromJson(e)).toList();
      final filtrados = todos.where((p) => p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase())).toList();

      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in filtrados) {
        agrupados.putIfAbsent(p.nombre, () => []).add(p);
      }

      setState(() {
        principiosUnicos = agrupados;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar JSON: $e');
      if (mounted) {
        setState(() => cargando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar principios: ${e.toString()}')),
        );
      }
    }
  }

  void cargarComportamientosEvaluados() async {
    try {
      final calificaciones = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);
      if (mounted) {
        setState(() {
          comportamientosEvaluados = calificaciones
              .where((c) => c.idDimension.toString() == widget.dimensionId)
              .map((c) => c.comportamiento)
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error al cargar comportamientos evaluados: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar evaluaciones previas: ${e.toString()}')),
        );
      }
    }
  }

  void agregarComportamientoEvaluado(String comportamiento) {
    if (!comportamientosEvaluados.contains(comportamiento)) {
      setState(() {
        comportamientosEvaluados.add(comportamiento);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Dimensión ${widget.dimensionId.toUpperCase()} - ASOCIADO: ${widget.asociado.nombre.toUpperCase()}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            tooltip: 'Ver Tablas de Resultados',
            onPressed: () {
              final String evaluacionIdParaTabla = const Uuid().v4();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresaId: widget.empresa.id,
                    dimension: widget.dimensionId,
                    empresa: widget.empresa,
                    evaluacionId: evaluacionIdParaTabla,
                    asociadoId: widget.asociado.id,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: cargando
          ? const Center(child: CircularProgressIndicator())
          : principiosUnicos.isEmpty
              ? const Center(child: Text('No hay principios para este nivel y dimensión'))
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Nivel: ${widget.asociado.cargo.toUpperCase()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: principiosUnicos.length,
                          itemBuilder: (context, index) {
                            final entry = principiosUnicos.entries.elementAt(index);
                            return StatefulBuilder(
                              builder: (context, setStateTile) {
                                final totalComportamientos = entry.value.length;
                                final evaluados = entry.value.where((p) {
                                  final comportamientoNombre = p.benchmarkComportamiento.split(":").first.trim();
                                  return comportamientosEvaluados.contains(comportamientoNombre);
                                }).length;
                                final progreso = totalComportamientos == 0 ? 0.0 : evaluados / totalComportamientos;

                                return Card(
                                  elevation: 3,
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ExpansionTile(
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        LinearProgressIndicator(
                                          value: progreso,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(progreso == 1.0 ? Colors.blueAccent : Colors.green),
                                        ),
                                        const SizedBox(height: 4),
                                        Text('$evaluados de $totalComportamientos comportamientos evaluados', style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();
                                      final evaluado = comportamientosEvaluados.contains(comportamientoNombre);

                                      return ListTile(
                                        title: Text(
                                          comportamientoNombre,
                                          style: TextStyle(
                                            color: evaluado ? Colors.green : Colors.black87,
                                            fontWeight: evaluado ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: Text(evaluado ? 'Evaluado (Editar)' : 'Ir a evaluación', style: const TextStyle(fontSize: 12)),
                                        trailing: evaluado
                                            ? IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue),
                                                tooltip: 'Editar Calificación',
                                                onPressed: () async {
                                                  final nuevoPuntaje = await showDialog<int>(
                                                    context: context,
                                                    builder: (context) {
                                                      int? tempScore;
                                                      return AlertDialog(
                                                        title: const Text('Editar Calificación'),
                                                        content: TextField(
                                                          keyboardType: TextInputType.number,
                                                          decoration: const InputDecoration(labelText: 'Nuevo Puntaje (0-100)'),
                                                          onChanged: (value) {
                                                            tempScore = int.tryParse(value);
                                                          },
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () => Navigator.pop(context),
                                                            child: const Text('Cancelar'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed: () {
                                                              if (tempScore != null && tempScore! >= 0 && tempScore! <= 100) {
                                                                Navigator.pop(context, tempScore);
                                                              } else {
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  const SnackBar(content: Text('Puntaje debe estar entre 0 y 100')),
                                                                );
                                                              }
                                                            },
                                                            child: const Text('Guardar'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );

                                                  if (nuevoPuntaje != null) {
                                                    await _supabaseService.actualizarPuntajeComportamiento(
                                                      empresaId: widget.empresa.id,
                                                      asociadoId: widget.asociado.id,
                                                      dimensionId: widget.dimensionId,
                                                      comportamiento: comportamientoNombre,
                                                      nuevoPuntaje: nuevoPuntaje,
                                                    );
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      const SnackBar(content: Text('Calificación actualizada')),
                                                    );
                                                  }
                                                },
                                              )
                                            : const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                                        onTap: () async {
                                          final String evaluacionIdParaComportamiento = const Uuid().v4();

                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: evaluacionIdParaComportamiento,
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                                dimension: widget.dimensionId,
                                              ),
                                            ),
                                          );
                                          if (resultado != null && resultado == 'guardado' && !comportamientosEvaluados.contains(comportamientoNombre)) {
                                            setState(() {
                                              comportamientosEvaluados.add(comportamientoNombre);
                                            });
                                            setStateTile(() {});
                                          } else if (resultado == 'guardado') {
                                            setStateTile(() {});
                                          }
                                        },
                                      );
                                    }).toList(),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (principiosUnicos.isEmpty || principiosUnicos.values.every((list) => list.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No hay principios cargados para iniciar una nueva evaluación desde aquí.')),
            );
            return;
          }

          PrincipioJson? primerPrincipioParaEvaluar;
          try {
            primerPrincipioParaEvaluar = principiosUnicos.values.firstWhere((list) => list.isNotEmpty).first;
          // ignore: empty_catches
          } catch (e) {}

          if (primerPrincipioParaEvaluar == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No se encontró un comportamiento válido para iniciar la evaluación.')),
            );
            return;
          }

          final String evaluacionIdParaNuevaEvaluacion = const Uuid().v4();

          final resultado = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (_) => ComportamientoEvaluacionScreen(
                principio: primerPrincipioParaEvaluar!,
                cargo: widget.asociado.cargo,
                evaluacionId: evaluacionIdParaNuevaEvaluacion,
                dimensionId: widget.dimensionId,
                empresaId: widget.empresa.id,
                asociadoId: widget.asociado.id,
                dimension: widget.dimensionId,
              ),
            ),
          );

          if (resultado != null && resultado == 'guardado') {
            cargarComportamientosEvaluados();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nueva evaluación iniciada/guardada.')),
            );
          }
        },
        backgroundColor: Colors.blue,
        tooltip: 'Iniciar Nueva Evaluación (Primer Comportamiento)',
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }
}

class ProgresoAsociado {
  static final Map<String, Set<String>> _map = {};
  static void marcarComoEvaluado(String id, String comp) {
    _map.putIfAbsent(id, () => {}).add(comp);
  }

  static bool estaEvaluado(String id, String comp) => _map[id]?.contains(comp) ?? false;
}

extension ProgresoSupabase on SupabaseService {
  Future<void> registrarComportamientoEvaluado({
    required String empresaId,
    required String asociadoId,
    required String dimensionId,
    required String comportamiento,
    int puntajeInicial = 0,
  }) async {
    final response = await Supabase.instance.client
        .from('calificaciones')
        .select('id')
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', empresaId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 0)
        .eq('comportamiento', comportamiento)
        .maybeSingle();

    if (response == null) {
      await Supabase.instance.client.from('calificaciones').insert({
        'id': const Uuid().v4(),
        'id_asociado': asociadoId,
        'id_empresa': empresaId,
        'id_dimension': int.tryParse(dimensionId),
        'comportamiento': comportamiento,
        'puntaje': puntajeInicial,
      });
    }
  }
}

extension EditarCalificacionSupabase on SupabaseService {
  Future<void> actualizarPuntajeComportamiento({
    required String empresaId,
    required String asociadoId,
    required String dimensionId,
    required String comportamiento,
    required int nuevoPuntaje,
  }) async {
    final existeResponse = await Supabase.instance.client
        .from('calificaciones')
        .select('id')
        .eq('id_asociado', asociadoId)
        .eq('id_empresa', empresaId)
        .eq('id_dimension', int.tryParse(dimensionId) ?? 0)
        .eq('comportamiento', comportamiento)
        .maybeSingle();

    if (existeResponse == null) {
      await Supabase.instance.client.from('calificaciones').insert({
        'id': const Uuid().v4(),
        'id_asociado': asociadoId,
        'id_empresa': empresaId,
        'id_dimension': int.tryParse(dimensionId),
        'comportamiento': comportamiento,
        'puntaje': nuevoPuntaje,
      });
    } else {
      await Supabase.instance.client
          .from('calificaciones')
          .update({'puntaje': nuevoPuntaje})
          .eq('id_asociado', asociadoId)
          .eq('id_empresa', empresaId)
          .eq('id_dimension', int.tryParse(dimensionId) ?? 0)
          .eq('comportamiento', comportamiento);
    }
  }
}
