import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:flutter/material.dart';
import 'package:applensys/screens/dashboard_screen.dart';
import 'package:applensys/screens/historial_screen.dart';
import 'package:applensys/screens/perfil_screen.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DrawerLensys extends StatelessWidget {
  final dynamic empresa;
  final dynamic dimensionId;

  const DrawerLensys({
    super.key,
    required this.empresa,
    required this.dimensionId,
  });

  Future<Map<String, dynamic>> _getUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'nombre': 'Usuario', 'foto_url': null};
    final data =
        await Supabase.instance.client
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
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final userEmail = user?.email ?? 'usuario@ejemplo.com';

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
                  decoration: const BoxDecoration(color: Colors.indigo),
                  accountName: Text(
                    nombre,
                    style: const TextStyle(fontSize: 18),
                  ),
                  accountEmail: Text(userEmail),
                  currentAccountPicture:
                      (fotoUrl != null && fotoUrl != '')
                          ? CircleAvatar(backgroundImage: NetworkImage(fotoUrl))
                          : const CircleAvatar(
                            backgroundColor: Colors.white,
                            child: Icon(
                              Icons.person,
                              size: 40,
                              color: Colors.indigo,
                            ),
                          ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.black),
              title: const Text("Inicio"),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmpresasScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Colors.black),
              title: const Text("Historial"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistorialScreen(empresas: []),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: Colors.black),
              title: const Text("Perfil"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PerfilScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.dashboard, color: Colors.black),
              title: const Text("Dashboard"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DashboardScreen()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                "Cerrar sesión",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final supabaseService = SupabaseService();
                await supabaseService.signOut();

                Navigator.pushAndRemoveUntil(
                  // ignore: use_build_context_synchronously
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
