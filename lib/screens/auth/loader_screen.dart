import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class LoaderScreen extends StatefulWidget {
  const LoaderScreen({super.key});

  @override
  State<LoaderScreen> createState() => _LoaderScreenState();
}

class _LoaderScreenState extends State<LoaderScreen> {
  bool _isReady = false;
  static const String _appVersion = '1.0.0';
  static const String _appName = 'Lensys Trainning Center';
  static const String _supportEmail = 'sistemas@lensys.com.mx';
  static const String _developer = 'Raúl Cano Briseño';
  static const String _autor = 'Autor: Francisco Ramirez Reséndiz';

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDarkMode
        ? 'assets/logoblanco.webp'
        : 'assets/logo.webp';
    final primaryColor = const Color(0xFF003056);
    final secondaryColor =
        isDarkMode ? Colors.grey[700] : Colors.grey[600];
    final welcomeTextColor = isDarkMode
        ? Colors.grey[300]
        : const Color.fromARGB(255, 221, 221, 221);
    final loaderBackground = isDarkMode
        ? Colors.grey[900]
        : const Color.fromARGB(255, 254, 255, 255);
    final diagonalPainterColor = isDarkMode
        ? Colors.grey[850]!
        : const Color(0xFF003056);

    if (!_isReady) {
      return Scaffold(
        backgroundColor: primaryColor,
        body: Center(
          child: CircularProgressIndicator(
              color: secondaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: loaderBackground,
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: DiagonalPainter(color: diagonalPainterColor),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 34),
                Text(
                  'LEAN TRAINING CENTER',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Bienvenido a la \n' 
                      'aplicación oficial',
                  style: TextStyle(
                    fontSize: 18,
                    color: welcomeTextColor,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator
                          .pushReplacementNamed(
                              context, '/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            primaryColor,
                        foregroundColor:
                            secondaryColor,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                      ),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator
                          .pushReplacementNamed(
                              context,
                              '/register'),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: primaryColor),
                        backgroundColor:
                            Colors.white,
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  12),
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                                vertical: 16),
                      ),
                      child: const Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              Color(0xFF003056),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Derechos y autor
               
                   
                // Icono de signo de admiración
                Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.error_outline,
                      size: 24,
                      color: Color(0xFF003056),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text('Acerca de $_appName'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Nombre de la app: $_appName'),
                              const SizedBox(height: 8),
                              Text('Versión: $_appVersion'),
                              const SizedBox(height: 8),
                              Text('Contacto: $_supportEmail'),
                              const SizedBox(height: 8),
                              Text('Desarrollador: $_developer'),
                              const SizedBox(height: 8),
                              Text(_autor),
                              const SizedBox(height: 8),
                              const Text('© 2025 Lensys Trainning Center. Todos los derechos reservados.'),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DiagonalPainter extends CustomPainter {
  final Color color;
  const DiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF003056)
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
