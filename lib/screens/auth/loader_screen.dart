import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDarkMode ? 'assets/logoblanco.webp' : 'assets/logo.webp';
    final primaryColor = isDarkMode ? const Color(0xFF003056): const Color(0xFF003056);
    final secondaryColor = isDarkMode ? Colors.grey[700] :Colors.grey[600];
    final textColor = isDarkMode ? Colors.white : const Color.fromARGB(255, 255, 255, 255);
    final welcomeTextColor = isDarkMode ? Colors.grey[300] : const Color.fromARGB(255, 221, 221, 221);
    final loaderScreenBackgroundColor = isDarkMode ? Colors.grey[900] : const Color.fromARGB(255, 254, 255, 255);
    final diagonalPainterColor = isDarkMode ? Colors.grey[850]! : const Color(0xFF003056);


    if (!_isReady) {
      return Scaffold(
        backgroundColor: primaryColor, // Adaptado
        body: Center(
          child: CircularProgressIndicator(color: secondaryColor), // Adaptado
        ),
      );
    }

    return Scaffold(
      backgroundColor: loaderScreenBackgroundColor, // Adaptado
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: DiagonalPainter(color: diagonalPainterColor)), // Adaptado
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 34),
                Text(
                  'LEAN TRAINING CENTER',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.white, // Texto sobre el DiagonalPainter siempre blanco
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bienvenido a la \naplicación oficial',
                    style: TextStyle(
                    fontSize: 18,
                    color: welcomeTextColor, // Adaptado para el fondo del DiagonalPainter
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: SizedBox(
                    height: 140,
                    child: Image.asset(logoAsset), // Adaptado
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
                        backgroundColor: primaryColor, // Adaptado
                        foregroundColor: secondaryColor, // Adaptado
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Iniciar Sesión',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        '/register',
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: primaryColor), // Adaptado
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            color:const Color(0xFF003056),
                          ),
                        ),

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
  const DiagonalPainter({required Color color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003056) // siempre este color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(0, size.height / 2)
      ..lineTo(0, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

