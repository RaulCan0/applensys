import 'package:applensys/models/asociado.dart';
import 'package:applensys/models/principio_json.dart';
import 'package:applensys/screens/tablas_screen.dart';
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
      final List<dynamic> datos = await JsonService.cargarJson(
        '${widget.dimensionId}.json',
      );
      if (datos.isEmpty) {
        throw Exception('El archivo JSON está vacío.');
      }

      final todos = datos.map((e) => PrincipioJson.fromJson(e)).toList();

      final filtrados =
          todos
              .where(
                (p) => p.nivel.toLowerCase().contains(
                  widget.asociado.cargo.toLowerCase(),
                ),
              )
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
          '${widget.dimensionId.toUpperCase()} - ${widget.asociado.nombre}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: Colors.indigo,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart_outlined),
            tooltip: 'Ver tabla resumen',
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
      body:
          cargando
              ? const Center(child: CircularProgressIndicator())
              : principiosUnicos.isEmpty
              ? const Center(
                child: Text(
                  'No hay principios para este nivel',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              )
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
                          'Principios',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        children:
                            principiosUnicos.entries.map((entry) {
                              return Card(
                                elevation: 3,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ExpansionTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Nivel: ${widget.asociado.cargo.toUpperCase()}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  children:
                                      entry.value.map((principio) {
                                        return ListTile(
                                          title: Text(
                                            principio.benchmarkComportamiento,
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          subtitle: const Text(
                                            'Ir a evaluación',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          trailing: const Icon(
                                            Icons.arrow_forward_ios,
                                          ),
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
                                                        ComportamientoEvaluacionScreen(
                                                          principio: principio,
                                                          cargo:
                                                              widget
                                                                  .asociado
                                                                  .cargo,
                                                          evaluacionId:
                                                              const Uuid().v4(),
                                                          dimensionId: '',
                                                        ),
                                              ),
                                            );
                                          },
                                        );
                                      }).toList(),
                                ),
                              );
                            }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
