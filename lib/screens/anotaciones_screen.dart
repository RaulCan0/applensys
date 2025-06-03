import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = ThemeData.dark(); // partimos de un tema oscuro
    return MaterialApp(
      title: 'Applensys',
      theme: base.copyWith(
        // CONFIGURAMOS EL COLOR PRIMARIO
        colorScheme: base.colorScheme.copyWith(
          primary: const Color(0xFF003056),
          onPrimary: Colors.white,
          surface: const Color(0xFF003056),
          onSurface: Colors.white,
          secondary: const Color(0xFF003056),
          onSecondary: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF003056),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF003056),
          foregroundColor: Colors.white, // title y icons de AppBar blancos
        ),
        // Hacemos que todo Text sea blanco por defecto
        textTheme: base.textTheme.apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF003056),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AnotacionesScreen(userId: 'tuUsuario'),
    );
  }
}

class AnotacionesScreen extends StatelessWidget {
  final String userId;

  const AnotacionesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anotaciones'),
      ),
      body: Center(
        child: Text('Bienvenido, $userId'),
      ),
    );
  }
}
