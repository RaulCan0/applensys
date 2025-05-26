// ignore_for_file: use_build_context_synchronously

import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import 'package:applensys/screens/detalles_evaluacion.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/historial_screen.dart';
import 'package:applensys/screens/perfil_screen.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/widgets/chat_scren.dart';
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
        color: Colors.white,
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
                    color: Color.fromARGB(255, 35, 47, 112),
                  ),
                  accountName: Text(nombre, style: TextStyle(fontSize: 18 * scaleFactor)),
                  accountEmail: Text(userEmail, style: TextStyle(fontSize: 14 * scaleFactor)),
                  currentAccountPicture: (fotoUrl != null && fotoUrl != '')
                      ? CircleAvatar(backgroundImage: NetworkImage(fotoUrl), radius: 30 * scaleFactor)
                      : CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 30 * scaleFactor,
                          child: Icon(Icons.person, size: 40 * scaleFactor, color: const Color.fromARGB(255, 35, 47, 112)),
                        ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Inicio", style: TextStyle(fontSize: 14 * scaleFactor)),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmpresasScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Resultados", style: TextStyle(fontSize: 14 * scaleFactor)),
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
              leading: Icon(Icons.insert_chart, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Detalle Evaluación", style: TextStyle(fontSize: 14 * scaleFactor)),
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
              leading: Icon(Icons.history, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Historial", style: TextStyle(fontSize: 14 * scaleFactor)),
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
                leading: Icon(Icons.manage_accounts, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Ajustes y Perfil", style: TextStyle(fontSize: 14 * scaleFactor)),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.dashboard, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Dashboard", style: TextStyle(fontSize: 14 * scaleFactor)),
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
              leading: Icon(Icons.chat, color: Colors.black, size: 24 * scaleFactor),
              title: Text("Chat", style: TextStyle(fontSize: 14 * scaleFactor)),
              onTap: () {
                Navigator.of(context).pop(); // Cierra el endDrawer (DrawerLensys)
                // Intenta abrir el drawer principal del Scaffold.
                // Esto asume que el Scaffold tiene un 'drawer' asignado (que debería ser ChatWidgetDrawer).
                Scaffold.of(context).openDrawer();
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.note_add, size: 24 * scaleFactor),
              title: Text('Mis Anotaciones', style: TextStyle(fontSize: 14 * scaleFactor)),
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
              leading: Icon(Icons.text_fields, color: Colors.black, size: 24 * scaleFactor),
              title: Text('Letra', style: TextStyle(fontSize: 14 * scaleFactor)),
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
                title: Text("Cerrar sesión", style: TextStyle(fontSize: 14 * scaleFactor)),
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