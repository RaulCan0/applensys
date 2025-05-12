// dimensiones_screen.dart

// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/empresa.dart';
import '../services/evaluacion_cache_service.dart';
import '../services/supabase_service.dart';
import '../widgets/drawer_lensys.dart';
import 'asociado_screen.dart';
import 'empresas_screen.dart';

class DimensionesScreen extends StatefulWidget {
  final Empresa empresa;
  final String evaluacionId;

  const DimensionesScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

  @override
  State<DimensionesScreen> createState() => _DimensionesScreenState();
}

class _DimensionesScreenState extends State<DimensionesScreen> {
  final List<Map<String, dynamic>> dimensiones = const [
    {
      'id': '1',
      'nombre': 'IMPULSORES CULTURALES',
      'icono': Icons.group,
      'color': Colors.indigo,
    },
    {
      'id': '2',
      'nombre': 'MEJORA CONTINUA',
      'icono': Icons.update,
      'color': Colors.green,
    },
    {
      'id': '3',
      'nombre': 'ALINEAMIENTO EMPRESARIAL',
      'icono': Icons.business,
      'color': Colors.red,
    },
  ];

  bool _evaluacionFinalizada = false;

  @override
  void initState() {
    super.initState();
    _verificarEstadoEvaluacion();
  }

  Future<void> _verificarEstadoEvaluacion() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _evaluacionFinalizada = prefs.getBool('evaluacion_finalizada_${widget.evaluacionId}') ?? false;
    });
  }

  Future<void> _guardarProgreso() async {
    await SupabaseService().guardarEvaluacionDraft(widget.evaluacionId);
    await EvaluacionCacheService().guardarPendiente(widget.evaluacionId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Progreso guardado localmente')),
    );
  }

  Future<void> _finalizarEvaluacion() async {
    try {
      

      // 2. Elimina caché local
      await EvaluacionCacheService().eliminarPendiente();

      // 3. Agrega al historial en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final historial = prefs.getStringList('empresas_historial') ?? [];
      final key = 'empresa_${widget.empresa.id}';

      if (!historial.contains(widget.empresa.id)) {
        historial.add(widget.empresa.id);
        await prefs.setStringList('empresas_historial', historial);
        await prefs.setString(key, jsonEncode(widget.empresa.toMap()));
      }

      // 4. Marca evaluación como 

      // 5. Mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evaluación finalizada y archivada')),
      );

      // 6. Redirige a EmpresasScreen
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const EmpresasScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al finalizar evaluación: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.indigo,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const EmpresasScreen()),
            );
          },
        ),
        title: Text(
          'Dimensiones - ${widget.empresa.nombre}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {
              scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: const DrawerLensys(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: dimensiones.length,
              itemBuilder: (context, index) {
                final dimension = dimensiones[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              dimension['icono'],
                              color: dimension['color'],
                              size: 36,
                            ),
                            title: Text(
                              dimension['nombre'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onTap: _evaluacionFinalizada
                                ? null
                                : () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AsociadoScreen(
                                          empresa: widget.empresa,
                                          dimensionId: dimension['id'],
                                          evaluacionId: widget.evaluacionId,
                                        ),
                                      ),
                                    );
                                    setState(() {});
                                  },
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<double>(
                            future: SupabaseService().obtenerProgresoDimension(
                              widget.empresa.id,
                              dimension['id'],
                            ),
                            initialData: 0.0,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    LinearProgressIndicator(),
                                    SizedBox(height: 4),
                                    Text('Cargando progreso...', style: TextStyle(fontSize: 12)),
                                  ],
                                );
                              }
                              if (snapshot.hasError) {
                                return const Text(
                                  'Error al cargar progreso',
                                  style: TextStyle(fontSize: 12, color: Colors.red),
                                );
                              }
                              final progreso = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  LinearProgressIndicator(
                                    value: progreso,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    color: dimension['color'],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${(progreso * 100).toStringAsFixed(1)}% completado', style: const TextStyle(fontSize: 12)),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _evaluacionFinalizada ? null : _guardarProgreso,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar evaluación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: _evaluacionFinalizada ? null : _finalizarEvaluacion,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
