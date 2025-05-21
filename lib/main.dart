import 'dart:async';
import 'package:flutter/material.dart';
import 'package:applensys/services/notification_service.dart';
import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';
import 'package:applensys/services/evaluacion_cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/screens/error_screen.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:applensys/screens/auth/recoveru_screee.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/providers/text_size_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) inicializa notificaciones
  await NotificationService.init();

  // 2) configura locator & cache
  setupLocator();
  await locator<EvaluacionCacheService>().init();

  // 3) envuelve errores globales
  runZonedGuarded(() async {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      Zone.current.handleUncaughtError(details.exception, details.stack!);
    };

    // 4) inicializa Supabase
    await Supabase.initialize(
      url: Configurations.mSupabaseUrl,
      anonKey: Configurations.mSupabaseKey,
    );

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    runApp(ProviderScope(child: ErrorScreen(error: error, stackTrace: stack)));
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Applensys',
      theme: ThemeData(
        textTheme: Theme.of(context).textTheme.apply(
          fontSizeFactor: ref.watch(textSizeProvider) / 14.0, // Ajustar el tamaño globalmente
        ),
      ),
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
