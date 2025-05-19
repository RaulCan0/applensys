import 'dart:async';
import 'package:flutter/material.dart';
import 'package:applensys/custom/configurations.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:applensys/screens/auth/recoveru_screee.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/error_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/custom/service_locator.dart';
import 'package:applensys/services/evaluacion_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
  runZonedGuarded(() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    };
    await Supabase.initialize(
      url: Configurations.mSupabaseUrl,
      anonKey: Configurations.mSupabaseKey,
    );
    // Inicializar cache de evaluaciones
    await locator<EvaluacionCacheService>().init();
    runApp(const MyApp());
  }, (error, stack) {
    runApp(ErrorScreen(error: error, stackTrace: stack));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Applensys',
   
      // Rutas nombradas para navegación consistente
      routes: {
        '/loaderScreen': (_) => const LoaderScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/recovery': (_) => const RecoveryScreen(),
        '/empresas': (_) => const EmpresasScreen(),
      },
      home: const LoaderScreen(),
    );
  }
}
