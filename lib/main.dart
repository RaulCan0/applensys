import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/custom/configurations.dart';
import 'package:applensys/custom/service_locator.dart';
import 'package:applensys/providers/text_size_provider.dart';
import 'package:applensys/providers/theme_provider.dart';
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:applensys/screens/auth/recoveru_screee.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: Configurations.mSupabaseUrl,
    anonKey: Configurations.mSupabaseKey,
  );
  setupLocator();
  await locator<EvaluacionCacheService>().init();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textSize = ref.watch(textSizeProvider);
    final scaleFactor = textSize / 14.0;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LensysApp',
      themeMode: themeMode,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF003056),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003056),
          foregroundColor: Colors.white,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF000000),
        scaffoldBackgroundColor: const Color.fromARGB(75, 206, 206, 206),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(75, 206, 206, 206),
          foregroundColor: Colors.black,
        ),
        textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
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