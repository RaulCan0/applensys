import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import '../models/asociado.dart';
import '../models/principio_json.dart';
import '../services/json_service.dart';
import 'comportamiento_evaluacion_screen.dart';
import 'tablas_screen.dart';

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
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarPrincipios();
  }

  Future<void> _cargarPrincipios() async {
    try {
      // Use proper string interpolation
      final datos = await JsonService.cargarJson('t${widget.dimensionId}.json');
      final todos = datos.map((e) => PrincipioJson.fromJson(e)).toList();
      final filtrados = todos.where((p) =>
        p.nivel.toLowerCase() == widget.asociado.cargo.toLowerCase()
      ).toList();
      final agrupados = <String, List<PrincipioJson>>{};
      for (var p in filtrados) {
        agrupados.putIfAbsent(p.nombre, () => []).add(p);
      }
      setState(() {
        principiosUnicos = agrupados;
        cargando = false;
      });
    } catch (e) {
      debugPrint('Error al cargar principios: $e');
      setState(() => cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dimensión ${widget.dimensionId} - ${widget.asociado.nombre}'),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TablasDimensionScreen(
                  dimension: 'Dimensión ${widget.dimensionId}',
                ),
              ),
            ),
          ),
        ],
      ),
      body: cargando
        ? const Center(child: CircularProgressIndicator())
        : principiosUnicos.isEmpty
          ? const Center(child: Text('No hay principios para este nivel'))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: ListView(
                children: principiosUnicos.entries.map((entry) {
                  final nombrePrincipio = entry.key;
                  final listaPrincipios = entry.value;
                  final total = listaPrincipios.length;
                  final completados = listaPrincipios.where((p) {
                    final comp = p.benchmarkComportamiento.split(':').first.trim();
                    return ProgresoAsociado.estaEvaluado(widget.asociado.id, comp);
                  }).length;
                  final progreso = total > 0 ? completados / total : 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ExpansionTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombrePrincipio,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          LinearProgressIndicator(value: progreso),
                          const SizedBox(height: 4),
                          Text('$completados de $total evaluados'),
                        ],
                      ),
                      children: listaPrincipios.map((principio) {
                        final nombreComp = principio.benchmarkComportamiento.split(':').first.trim();
                        final evaluado = ProgresoAsociado.estaEvaluado(widget.asociado.id, nombreComp);
                        return ListTile(
                          title: Text(
                            nombreComp,
                            style: TextStyle(
                              color: evaluado ? Colors.green : Colors.black,
                              fontWeight: evaluado ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: const Text('Ir a evaluación'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: evaluado ? null : () async {
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
                                  dimension: 'Dimensión ${widget.dimensionId}',
                                ),
                              ),
                            );
                            if (resultado != null) {
                              ProgresoAsociado.marcarComoEvaluado(widget.asociado.id, resultado);
                              setState(() {});
                            }
                          },
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              ),
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
