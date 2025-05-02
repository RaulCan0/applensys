// ARCHIVO: dimensiones_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:applensys/screens/asociado_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/empresa.dart';
import '../services/supabase_service.dart';
import '../widgets/drawer_lensys.dart';
import 'empresas_screen.dart';

class DimensionesScreen extends StatelessWidget {
  final Empresa empresa;
  final String evaluacionId;

  const DimensionesScreen({
    super.key,
    required this.empresa,
    required this.evaluacionId,
  });

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
          'Dimensiones - ${empresa.nombre}',
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AsociadoScreen(
                                    empresa: empresa,
                                    dimensionId: dimension['id'],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 10),
                          FutureBuilder<double>(
                            future: SupabaseService().obtenerProgresoDimension(
                              evaluacionId,
                              int.parse(dimension['id']) as String,
                            ),
                            initialData: 0.0,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const LinearProgressIndicator(),
                                    const SizedBox(height: 4),
                                    const Text(
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
                  onPressed: () async {
                    await SupabaseService().guardarEvaluacionDraft(evaluacionId);
                    await EvaluacionCacheService().guardarPendiente(evaluacionId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Progreso guardado localmente')),
                    );
                  },
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Finalizar evaluación'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                  onPressed: () async {
                    await SupabaseService().finalizarEvaluacion(evaluacionId);
                    await EvaluacionCacheService().eliminarPendiente();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Evaluación finalizada')),
                    );
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

class EvaluacionCacheService {
  static const _keyEvaluacionPendiente = 'evaluacion_pendiente';

  Future<void> guardarPendiente(String evaluacionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEvaluacionPendiente, evaluacionId);
  }

  Future<String?> obtenerPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEvaluacionPendiente);
  }

  Future<void> eliminarPendiente() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEvaluacionPendiente);
  }
}



/*import 'package:applensys/screens/dashboard_screen.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/asociado_screen.dart';

class DimensionesScreen extends StatelessWidget {
  final Empresa empresa;

  const DimensionesScreen({super.key, required this.empresa});

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
          'Dimensiones - ${empresa.nombre}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),
        ],
      ),
      drawer: DrawerLensys(),
      body: ListView.builder(
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
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
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
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AsociadoScreen(
                          empresa: empresa,
                          dimensionId: dimension['id'],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 30),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: GestureDetector(
            onTap: () {
              scaffoldKey.currentState?.openDrawer();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.menu, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}*/
