import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGuard extends StatefulWidget {
  const AuthGuard({super.key});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      _isLoggedIn = session != null;
    } catch (e) {
      debugPrint("❌ Error al recuperar la sesión: $e");
      _isLoggedIn = false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    // Si está logueado, va a Empresas, si no, a Login directamente
    return _isLoggedIn
        ? const EmpresasScreen()
        : const LoginScreen();
  }
}
