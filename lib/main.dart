import 'package:applensys/custom/configurations.dart';
import 'package:flutter/material.dart';
import 'screens/empresas_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: Configurations.mSupabaseUrl,
      anonKey: Configurations.mSupabaseKey,
    );
    debugPrint('Supabase inicializado correctamente');
    runApp(const MyApp());
  } catch (e) {
    debugPrint('Error al inicializar Supabase: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Evaluación Operacional',
      debugShowCheckedModeBanner: false,
      home: EmpresasScreen(),
    );
  }
}
