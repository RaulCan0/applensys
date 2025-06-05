// ignore_for_file: use_build_context_synchronously

import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/historial_screen.dart';
import 'package:applensys/screens/perfil_screen.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/widgets/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../main.dart';
import '../screens/anotaciones_screen.dart';
import 'package:applensys/providers/text_size_provider.dart';

class DrawerLensys extends ConsumerWidget {
  const DrawerLensys({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'nombre': 'Usuario', 'foto_url': null};
    final data = await Supabase.instance.client
        .from('usuarios')
        .select('nombre, foto_url')
        .eq('id', user.id)
        .single();
    return {
      'nombre': data['nombre'] ?? 'Usuario',
      'foto_url': data['foto_url'],
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'usuario@ejemplo.com';
    final textSize = ref.watch(textSizeProvider);
    final double scaleFactor = textSize / 14.0;

    return Drawer(
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor, // Cambiado para usar el color del tema
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _getUserData(),
              builder: (context, snapshot) {
                final nombre = snapshot.data?['nombre'] ?? 'Usuario';
                final fotoUrl = snapshot.data?['foto_url'];

                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration( 
                    color: Color(0xFF003056),
                  ),
                  accountName: Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 18 * scaleFactor,
                      color: Colors.white, 
                    ),
                  ),
                  accountEmail: Text(
                    userEmail,
                    style: TextStyle(
                      fontSize: 14 * scaleFactor,
                      // ignore: deprecated_member_use
                      color: Colors.white.withOpacity(0.8), 
                    ),
                  ),
                  currentAccountPicture: (fotoUrl != null && fotoUrl.isNotEmpty) // Asegúrate que fotoUrl no sea un string vacío
                      ? CircleAvatar(backgroundImage: NetworkImage(fotoUrl), radius: 30 * scaleFactor)
                      : CircleAvatar(
                          backgroundColor: Colors.white, 
                          radius: 30 * scaleFactor,
                          child: Icon(
                            Icons.person,
                            size: 40 * scaleFactor,
                            color: const Color(0xFF003056), 
                          ),
                        ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.home, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Inicio", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmpresasScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Resultados", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TablasDimensionScreen(
                      empresa: Empresa(
                        id: 'defaultId',
                        nombre: 'Default Empresa',
                        tamano: 'Default Tamano',
                        empleadosTotal: 0,
                        empleadosAsociados: [],
                        unidades: 'Default Unidades',
                        areas: 0,
                        sector: 'Default Sector',
                        createdAt: DateTime.now(),
                      ),
                      evaluacionId: '', empresaId: '', dimension: '', asociadoId: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.insert_chart, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Detalle Evaluación", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetallesEvaluacionScreen(
                      dimensionesPromedios: const {},
                      promedios: const {},
                      empresa: Empresa(
                        id: '',
                        nombre: '',
                        tamano: '',
                        empleadosTotal: 0,
                        empleadosAsociados: [],
                        unidades: '',
                        areas: 0,
                        sector: '',
                        createdAt: DateTime.now(),
                      ),
                      evaluacionId: '', dimension: '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Historial", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialScreen(
                      empresas: [], // Proporcionar una lista vacía o los datos reales
                      empresasHistorial: [], // Proporcionar una lista vacía o los datos reales
                    ),
                  ),
                );
              },
            ),
            ListTile(
                leading: Icon(Icons.manage_accounts, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Ajustes y Perfil", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Dashboard", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DashboardScreen(
                      empresa: Empresa(
                        id: '',
                        nombre: '',
                        tamano: '',
                        empleadosTotal: 0,
                        empleadosAsociados: [],
                        unidades: '',
                        areas: 0,
                        sector: '',
                        createdAt: DateTime.now(),
                      ),
                      evaluacionId: '',
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.chat, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text("Chat", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.of(context).pop(); // Cierra el endDrawer (DrawerLensys)
                // Intenta abrir el drawer principal del .
                Scaffold.of(context).openDrawer();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.note_add, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text('Mis Anotaciones', style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AnotacionesScreen(userId: Supabase.instance.client.auth.currentUser!.id),
                  ),
                );
              },
            ),
            const Divider(),
            // Selector de tamaño de letra
            ListTile(
              leading: Icon(Icons.text_fields, color: Theme.of(context).iconTheme.color, size: 24 * scaleFactor),
              title: Text('Letra', style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              trailing: DropdownButton<double>(
                value: ref.watch(textSizeProvider),
                iconSize: 24 * scaleFactor,
                items: [
                  DropdownMenuItem(value: 12.0, child: Text('CH', style: TextStyle(fontSize: 12 * scaleFactor))),
                  DropdownMenuItem(value: 14.0, child: Text('M', style: TextStyle(fontSize: 14 * scaleFactor))),
                  DropdownMenuItem(value: 16.0, child: Text('G', style: TextStyle(fontSize: 16 * scaleFactor))),
                ],
                onChanged: (size) {
                  if (size != null) {
                    ref.read(textSizeProvider.notifier).state = size;
                  }
                },
              ),
            ),
            const Divider(),
            ListTile(
                leading: Icon(Icons.logout, color: Colors.red, size: 24 * scaleFactor),
                title: Text("Cerrar sesión", style: TextStyle(fontSize: 14 * scaleFactor, color: Theme.of(context).textTheme.bodyLarge?.color)),
              onTap: () async {
                await Supabase.instance.client.auth.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoaderScreen()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
// AÑADIDO: Servicio singleton que notifica cambios en tablaDatos
class DetallesEvaluacionService extends ChangeNotifier {
  static final DetallesEvaluacionService _instance = DetallesEvaluacionService._();
  factory DetallesEvaluacionService() => _instance;
  DetallesEvaluacionService._() {
    // inicializa con los datos actuales
    _tabla = TablasDimensionScreen.tablaDatos;
    // se suscribe a futuros cambios
    TablasDimensionScreen.dataChanged.addListener(_onDataChanged);
  }

  late Map<String, Map<String, List<Map<String, dynamic>>>> _tabla;
  Map<String, Map<String, List<Map<String, dynamic>>>> get tablaDatos => _tabla;

  void _onDataChanged() {
    _tabla = TablasDimensionScreen.tablaDatos;
    notifyListeners();
  }

  @override
  void dispose() {
    TablasDimensionScreen.dataChanged.removeListener(_onDataChanged);
    super.dispose();
  }
}