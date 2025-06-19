// ignore_for_file: use_build_context_synchronously


import 'package:applensys/screens/shingo_result.dart';
import 'package:applensys/screens/tabla_resumen_global.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:applensys/screens/asociado_screen.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/widgets/chat_screen.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';
import 'package:applensys/services/domain/evaluacion_service.dart';
import '../models/empresa.dart';

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

    // Define una altura constante para todas las cards
    const double cardHeight = 150; // Puedes ajustar este valor

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
              itemCount: 5,
              itemBuilder: (context, index) {
                Widget cardItem;
                if (index < dimensiones.length) {
                  final dimension = dimensiones[index];
                  cardItem = _buildCard(
                    icon: dimension['icono'],
                    color: dimension['color'],
                    title: dimension['nombre'],
                    child: FutureBuilder<double>(
                      future: evaluacionService.obtenerProgresoDimension(
                        widget.empresa.id, // Asumiendo que widget.empresa.id es String
                        dimension['id'],   // Asumiendo que dimension['id'] es String
                      ),
                      builder: (context, snapshot) {
                        final progreso = (snapshot.data ?? 0.0).clamp(0.0, 1.0);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min, // Para que la columna no intente expandirse innecesariamente
                          children: [
                            LinearProgressIndicator(
                              value: progreso,
                              minHeight: 8,
                              backgroundColor: const Color.fromARGB(255, 156, 156, 156),
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
                      if (mounted) { // Buena práctica verificar 'mounted' después de un await
                        setState(() {});
                      }
                    },
                  );
                } else if (index == 3) {
                  cardItem = _buildCard(
                    icon: Icons.insert_chart,
                    color: Colors.orange,
                    title: 'Resultados',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ShingoResultSheet(
                              title: 'Resultados',
                              initialData: ShingoResultData(), // Replace with appropriate default or required data
                            ),
                          ),
                        );
                    },
                  );
                } // index == 4
                 else { // index == 4
  cardItem = _buildCard(
    icon: Icons.assignment_turned_in,
    color: Colors.blue,
    title: 'Evaluación Final',
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TablaScoreGlobal(empresa: widget.empresa, detalles: [], evaluaciones: [],),
        ),
      );
    },
  );
} 
                
                // Envolver la cardItem con SizedBox para darle una altura fija
                return SizedBox(
                  height: cardHeight,
                  child: cardItem,
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
                    foregroundColor: const Color.fromARGB(255, 212, 209, 209),
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
                    label: const Text('Finalizar evaluación', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 94, 156, 96)),
                  onPressed: () async {
                    try {
                      final cache = EvaluacionCacheService();
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

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    Widget? child,
    required VoidCallback onTap,
  }) {
    // final screenSize = MediaQuery.of(context).size; // No se usa aquí
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // Reducido el padding vertical para mejor ajuste con altura fija
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              // Asegurar que la columna se centre o se expanda si es necesario dentro de la Card
              // dependiendo del diseño deseado. Por ahora, se deja como está.
              // mainAxisAlignment: MainAxisAlignment.center, // Podrías usar esto para centrar verticalmente el contenido
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 36),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (child != null) ...[
                  const SizedBox(height: 10),
                  // Si el child puede crecer, y quieres que la card se expanda,
                  // considera envolver el child con Expanded si la Column está dentro de otra Column/Row flexible.
                  // Aquí, como la Card tiene altura fija por el SizedBox externo, el child se adaptará o cortará.
                  child,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

