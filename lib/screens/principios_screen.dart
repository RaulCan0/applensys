import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/principio_json.dart';
import 'package:applensys/screens/tablas_screen.dart' as tablas_screen;
import 'package:applensys/services/domain/json_service.dart';
import 'package:applensys/services/domain/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';

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

  String nombreDimension(String id) {
    switch (id) {
      case '1':
        return 'IMPULSORES CULTURALES';
      case '2':
        return 'MEJORA CONTINUA';
      case '3':
        return 'ALINEAMIENTO EMPRESARIAL';
      default:
        return 'DIMENSIÓN DESCONOCIDA';
    }
  }

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
    }
  }

  void cargarComportamientosEvaluados() async {
    try {
      final calificaciones = await _supabaseService.getCalificacionesPorAsociado(widget.asociado.id);
      setState(() {
        comportamientosEvaluados = calificaciones
            .where((c) => c.idDimension.toString() == widget.dimensionId)
            .map((c) => c.comportamiento.toString())
            .toList();
      });
    } catch (e) {
      debugPrint('Error al cargar comportamientos evaluados: $e');
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
            ' ${nombreDimension(widget.dimensionId)}',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresaId: widget.empresa.id,
                    dimension: '',
                    empresa: widget.empresa,
                    evaluacionId: '',
                    asociadoId: '',
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
              ? const Center(child: Text('No hay principios para este nivel'))
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
                          child: Center(
                            child: Text(
                              'EVALUANDO A: ${widget.asociado.nombre}\n'
                              'Nivel Organizacional: ${widget.asociado.cargo.toLowerCase() == 'miembro' ? 'MIEMBRO DE EQUIPO' : widget.asociado.cargo.toUpperCase()}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 15, fontFamily: 'Arial'),
                            ),
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

                                return Container(
                                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Color.lerp(Colors.white, Colors.green[100], progreso),
                                    boxShadow: [
                                      // ignore: deprecated_member_use
                                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 3)),
                                    ],
                                  ),
                                  child: ExpansionTile(
                                    tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    childrenPadding: const EdgeInsets.only(bottom: 10),
                                    title: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          entry.key,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '$evaluados de $totalComportamientos comportamientos evaluados',
                                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final comportamientoNombre = principio.benchmarkComportamiento.split(":").first.trim();
                                      return ListTile(
                                        title: Text(
                                          comportamientoNombre,
                                          style: TextStyle(
                                            color: comportamientosEvaluados.contains(comportamientoNombre) ? Colors.green : Colors.black,
                                            fontWeight: comportamientosEvaluados.contains(comportamientoNombre) ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: const Text('Ir a evaluación'),
                                        trailing: const Icon(Icons.arrow_forward_ios),
                                        onTap: () async {
                                          final resultado = await Navigator.push<String>(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ComportamientoEvaluacionScreen(
                                                principio: principio,
                                                cargo: widget.asociado.cargo,
                                                evaluacionId: const Uuid().v4(),
                                                dimensionId: widget.dimensionId,
                                                empresaId: widget.empresa.id,
                                                asociadoId: widget.asociado.id,
                                                dimension: '',
                                              ),
                                            ),
                                          );
                                          if (resultado != null && !comportamientosEvaluados.contains(resultado)) {
                                            setState(() {
                                              comportamientosEvaluados.add(resultado);
                                            });
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
    );
  }
}