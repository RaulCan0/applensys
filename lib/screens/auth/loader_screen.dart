import 'package:applensys/screens/auth/login_screen.dart';
import 'package:applensys/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';

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
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomPaint(size: Size.infinite, painter: DiagonalPainter()),
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
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Bienvenido a la \naplicación oficial',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color.fromARGB(255, 156, 152, 152),
                  ),
                ),
                const SizedBox(height: 50),
                Center(
                  child: SizedBox(
                    height: 140,
                    child: Image.asset('assets/logo.png'),
                  ),
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Iniciar Sesión', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo,
                        side: const BorderSide(color: Colors.indigo, width: 2),
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Registrarse', style: TextStyle(fontSize: 16)),
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
      ..color = Colors.indigo
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
