// lib/main.dart

import 'dart:async';
import 'package:applensys/providers/text_size_provider.dart';
import 'package:applensys/screens/auth/recoveru_screee.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';
import 'package:applensys/providers/theme_provider.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/screens/error_screen.dart';
import 'package:applensys/services/domain/notification_service.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Supabase.initialize(
      url: Configurations.mSupabaseUrl,
      anonKey: Configurations.mSupabaseKey,
    );

    await NotificationService.init();
    setupLocator();
    await locator<EvaluacionCacheService>().init();

    runApp(const ProviderScope(child: MyApp()));
  }, (error, stack) {
    runApp(ProviderScope(
      child: ErrorScreen(error: error, stackTrace: stack),
    ));
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    Zone.current.handleUncaughtError(details.exception, details.stack!);
  };
}
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider); // 

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LensysApp',
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF003056),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003056),
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme, // Cambiado de Theme.of(context).textTheme
        ).apply(fontSizeFactor: textSize / 14.0), // 👈 Aplicar tamaño relativo
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
        ).apply(fontSizeFactor: textSize / 14.0), // 👈 También en oscuro
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
