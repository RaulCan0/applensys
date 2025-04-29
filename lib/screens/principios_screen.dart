import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/principio_json.dart';
import 'package:applensys/screens/tablas_screen.dart' as tablas_screen;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import '../services/json_service.dart';
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
    required String dimensionNombre,
  });

  @override
  State<PrincipiosScreen> createState() => _PrincipiosScreenState();
}

class _PrincipiosScreenState extends State<PrincipiosScreen> {
  Map<String, List<PrincipioJson>> principiosUnicos = {};
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    cargarPrincipios();
  }

  Future<void> cargarPrincipios() async {
    try {
      final List<dynamic> datos =
          await JsonService.cargarJson('t${widget.dimensionId}.json');
      if (datos.isEmpty) {
        throw Exception('El archivo JSON está vacío.');
      }

      final todos = datos.map((e) => PrincipioJson.fromJson(e)).toList();
      final filtrados = todos
          .where((p) =>
              p.nivel.toLowerCase().contains(widget.asociado.cargo.toLowerCase()))
          .toList();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Dimensión ${widget.dimensionId.toUpperCase()} - ASOCIADO: ${widget.asociado.nombre}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => tablas_screen.TablasDimensionScreen(
                    empresaId: widget.empresa.id,
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
                          child: Text(
                            'Nivel: ${widget.asociado.cargo.toUpperCase()}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
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
                                  final nombre = p.benchmarkComportamiento
                                      .split(":")
                                      .first
                                      .trim();
                                  return ProgresoAsociado.estaEvaluado(
                                      widget.asociado.id, nombre);
                                }).length;
                                final progreso = totalComportamientos == 0
                                    ? 0.0
                                    : evaluados / totalComportamientos;

                                return Card(
                                  elevation: 3,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: ExpansionTile(
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          valueColor:
                                              const AlwaysStoppedAnimation<Color>(
                                                  Colors.green),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                            '$evaluados de $totalComportamientos comportamientos evaluados'),
                                      ],
                                    ),
                                    children: entry.value.map((principio) {
                                      final nombreComportamiento = principio
                                          .benchmarkComportamiento
                                          .split(":")
                                          .first
                                          .trim();
                                      final evaluado =
                                          ProgresoAsociado.estaEvaluado(
                                              widget.asociado.id,
                                              nombreComportamiento);

                                      return ListTile(
                                        title: Text(
                                          nombreComportamiento,
                                          style: TextStyle(
                                            color: evaluado
                                                ? Colors.green
                                                : Colors.black,
                                            fontWeight: evaluado
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        subtitle: const Text('Ir a evaluación'),
                                        trailing: const Icon(
                                            Icons.arrow_forward_ios),
                                        onTap: evaluado
                                            ? null
                                            : () async {
                                                final resultado =
                                                    await Navigator.push<String>(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ComportamientoEvaluacionScreen(
                                                      principio: principio,
                                                      cargo:
                                                          widget.asociado.cargo,
                                                      evaluacionId:
                                                          const Uuid().v4(),
                                                      dimensionId:
                                                          widget.dimensionId,
                                                      empresaId:
                                                          widget.empresa.id,
                                                      asociadoId:
                                                          widget.asociado.id,
                                                      dimension:
                                                          'Dimensión ${widget.dimensionId}',
                                                    ),
                                                  ),
                                                );
                                                if (resultado != null) {
                                                  ProgresoAsociado
                                                      .marcarComoEvaluado(
                                                          widget.asociado.id,
                                                          resultado);
                                                  setState(() {});
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

class ProgresoAsociado {
  static final Map<String, Set<String>> comportamientosEvaluadosPorAsociado = {};

  static void marcarComoEvaluado(String asociadoId, String comportamiento) {
    if (!comportamientosEvaluadosPorAsociado.containsKey(asociadoId)) {
      comportamientosEvaluadosPorAsociado[asociadoId] = {};
    }
    comportamientosEvaluadosPorAsociado[asociadoId]!.add(comportamiento);
  }

  static bool estaEvaluado(String asociadoId, String comportamiento) {
    return comportamientosEvaluadosPorAsociado[asociadoId]
            ?.contains(comportamiento) ??
        false;
  }

  static void limpiarEvaluaciones(String asociadoId) {
    comportamientosEvaluadosPorAsociado.remove(asociadoId);
  }
}
