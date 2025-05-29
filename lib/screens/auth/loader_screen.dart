import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/providers/theme_provider.dart';

class LoaderScreen extends ConsumerStatefulWidget {
  const LoaderScreen({super.key});

  @override
  ConsumerState<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends ConsumerState<LoaderScreen> {
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Usar callback de post-frame para indicar preparado sin timers
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isReady = true);
    });
  }

  @override
  void dispose() {
    // Ningún Timer que cancelar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final logoAsset = themeMode == ThemeMode.dark ? 'assets/logoblanco.png' : 'assets/logo.png';

    // Define los colores para el estado de carga inicial (_isReady == false)
    final initialLoaderBackgroundColor = themeMode == ThemeMode.dark
        ? const Color.fromARGB(75, 206, 206, 206) // Fondo gris para modo oscuro
        : const Color.fromARGB(255, 254, 255, 255); // Fondo blanco para modo claro
    final initialLoaderIndicatorColor = themeMode == ThemeMode.dark
        ? Colors.white // Indicador blanco en fondo gris oscuro
        : const Color(0xFF003056); // Indicador azul en fondo blanco

    if (!_isReady) {
      return Scaffold(
        backgroundColor: initialLoaderBackgroundColor, // Aplicar color de fondo dinámico
        body: Center(
          child: CircularProgressIndicator(color: initialLoaderIndicatorColor), // Aplicar color de indicador dinámico
        ),
      );
    }

    // Define los colores para el estado principal (_isReady == true)
    final mainScaffoldBackgroundColor = themeMode == ThemeMode.dark
        ? const Color.fromARGB(75, 206, 206, 206) // Fondo para modo oscuro
        : const Color.fromARGB(255, 254, 255, 255); // Fondo para modo claro

    // Colores para los botones (se mantienen fijos según diseño original)
    const elevatedButtonBackgroundColor = Color(0xFF003056);
    const elevatedButtonForegroundColor = Colors.white;
    const outlinedButtonSideColor = Color(0xFF003056);
    const outlinedButtonBackgroundColor = Colors.white; // Fondo del botón Outlined
    const outlinedButtonForegroundColor = Color(0xFF003056); // Color del texto del botón Outlined

    // Colores para el texto sobre el DiagonalPainter (se mantienen fijos)
    const headerTextColor = Colors.white;
    const subHeaderTextColor = Color.fromARGB(255, 221, 221, 221);


    return Scaffold(
      backgroundColor: mainScaffoldBackgroundColor,
      body: Stack(
        children: [
          // Pintor diagonal (se mantiene)
          CustomPaint(size: Size.infinite, painter: DiagonalPainter()),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 34),
                Text(
                  'LEANSYS TRAINING CENTER',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: headerTextColor, // Usar color definido
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Bienvenido a la \naplicación oficial',
                    style: TextStyle(
                    fontSize: 18,
                    color: subHeaderTextColor, // Usar color definido
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: SizedBox(
                    height: 140,
                    child: Image.asset(logoAsset),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/login',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: elevatedButtonBackgroundColor,
                        foregroundColor: elevatedButtonForegroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/register',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: outlinedButtonSideColor),
                        backgroundColor: outlinedButtonBackgroundColor,
                        foregroundColor: outlinedButtonForegroundColor, // Color del texto/icono para OutlinedButton
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Registrarse', style: TextStyle(fontSize: 16 /*, color: outlinedButtonForegroundColor - ya se aplica con foregroundColor del style*/)),

                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003056)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width, 0);
    path.lineTo(0, size.height / 2);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
