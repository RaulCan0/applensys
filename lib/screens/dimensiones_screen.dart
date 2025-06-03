// ignore_for_file: use_build_context_synchronously

import 'package:applensys/services/domain/evaluacion_service.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/empresa.dart';
import '../widgets/chat_scren.dart'; // Nueva importación
import '../widgets/drawer_lensys.dart';
import 'asociado_screen.dart';
import 'empresas_screen.dart';
import 'tablas_screen.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

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

class _DimensionesScreenState extends State<DimensionesScreen> with RouteAware {
  final EvaluacionService evaluacionService = EvaluacionService();

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    return Scaffold(
      key: scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
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
            onPressed: () => scaffoldKey.currentState?.openEndDrawer(),
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
                  padding: EdgeInsets.symmetric(
                    vertical: screenSize.height * 0.01,
                    horizontal: screenSize.width * 0.05,
                  ),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(dimension['icono'], color: dimension['color'], size: 36),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    dimension['nombre'],
                                    style: const TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<double>(
                              future: evaluacionService.obtenerProgresoDimension(
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
                                      Text(
                                        'Cargando progreso...',
                                        style: TextStyle(fontSize: 12),
                                      ),
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
                                    Text(
                                      '${(progreso * 100).toStringAsFixed(1)}% completado',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
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
                  label: const Text('Continuar más tarde'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF003056),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () async {
                    await EvaluacionCacheService().guardarPendiente(widget.evaluacionId);
                    await EvaluacionCacheService().guardarTablas(TablasDimensionScreen.tablaDatos);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progreso guardado localmente')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle, color: Colors.white),
                  label: const Text(
                    'Finalizar evaluación',
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () async {
                    try {
                      final cache = EvaluacionCacheService();
                      // Solo eliminar evaluación pendiente y luego limpiar datos de tabla
                      await cache.eliminarPendiente();
                      await cache.limpiarCacheTablaDatos();

                      TablasDimensionScreen.tablaDatos.clear();
                      TablasDimensionScreen.dataChanged.value =
                          !TablasDimensionScreen.dataChanged.value;

                      final prefs = await SharedPreferences.getInstance();
                      final hist = prefs.getStringList('empresas_historial') ?? [];
                      if (!hist.contains(widget.empresa.id)) {
                        hist.add(widget.empresa.id);
                        await prefs.setStringList('empresas_historial', hist);
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Evaluación finalizada y datos limpiados')),
                      );
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const EmpresasScreen()),
                        (route) => false,
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al finalizar: $e')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
