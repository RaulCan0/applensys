// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:applensys/screens/error_screen.dart';
import 'package:applensys/services/domain/notification_service.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

void main() {
  // Disable fatal zone check to avoid Zone mismatch errors
  BindingBase.debugZoneErrorsAreFatal = false;
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // Hacer fatales los errores de zona
      BindingBase.debugZoneErrorsAreFatal = true;
      // Redirigir errores de Flutter a la zona
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      };

      await Supabase.initialize(
        url: Configurations.mSupabaseUrl,
        anonKey: Configurations.mSupabaseKey,
      );
      await NotificationService.init();
      setupLocator();
      await locator<EvaluacionCacheService>().init();

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      runApp(
        ProviderScope(
          child: ErrorScreen(error: error, stackTrace: stack),
        ),
      );
    },
  );
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
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scaleFactor)),
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
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color.fromARGB(255, 0, 0, 0),
        scaffoldBackgroundColor: const Color.fromARGB(75, 206, 206, 206),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.dark().textTheme,
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
  /*// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
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
import 'package:applensys/screens/error_screen.dart';
import 'package:applensys/services/domain/notification_service.dart';
import 'package:applensys/services/local/evaluacion_cache_service.dart';

void main() {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      BindingBase.debugZoneErrorsAreFatal = true;
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        Zone.current.handleUncaughtError(details.exception, details.stack!);
      };

      await Supabase.initialize(
        url: Configurations.mSupabaseUrl,
        anonKey: Configurations.mSupabaseKey,
      );
      await NotificationService.init();
      setupLocator();
      await locator<EvaluacionCacheService>().init();

      runApp(const ProviderScope(child: MyApp()));
    },
    (error, stack) {
      runApp(
        ProviderScope(
          child: ErrorScreen(error: error, stackTrace: stack),
        ),
      );
    },
  );
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
          data: MediaQuery.of(context).copyWith(textScaleFactor: scaleFactor),
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
        textTheme: GoogleFonts.robotoTextTheme(
          ThemeData.light().textTheme,
        ),
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
*/