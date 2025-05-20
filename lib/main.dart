
import 'package:applensys/screens/auth/loader_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'custom/configurations.dart';
import 'package:applensys/providers/app_provider.dart';

const Color customIndigo = Color.fromARGB(255, 35, 47, 112);
const Color customGray = Color(0xFFF5F5F5); // Color gris claro

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
    debugPrint('Error al inicializar Supabase: \$e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: Consumer<FontProvider>(
        builder: (context, fontProvider, _) => MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Applensys',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: customIndigo,
              primary: customIndigo,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: customIndigo,
              foregroundColor: Colors.white,
              iconTheme: IconThemeData(color: Colors.white),
            ),
            scaffoldBackgroundColor: customGray, // Fondo gris para todas las pantallas
            textTheme: ThemeData.light().textTheme.apply(
                  fontSizeFactor: fontProvider.scale,
                  fontFamily: 'Roboto',
                ),
            useMaterial3: true,
          ),
          home: const LoaderScreen(),
        ),
      ),
    );
  }
}

class FontProvider extends ChangeNotifier {
  double _scale = 1.0;

  double get scale => _scale;

  void setScale(double newScale) {
    _scale = newScale;
    notifyListeners();
  }
}
