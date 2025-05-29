// login_screen.dart
import 'package:applensys/services/remote/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/providers/theme_provider.dart';
import 'package:applensys/screens/auth/recoveru_screee.dart';
import 'package:applensys/screens/empresas_screen.dart';
import 'package:applensys/custom/service_locator.dart';
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  void _showAlert(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showAlert('Error', 'Por favor, completa todos los campos');
      return;
    }

    // Validar formato de email
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _showAlert('Error', 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() => _isLoading = true);
    final authService = locator<AuthService>();
    final result = await authService.login(
      _emailController.text,
      _passwordController.text,
    );
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/empresas',
        (route) => false,
      );
    } else {
      if (!mounted) return;
      _showAlert('Error', result['message'] ?? 'Correo o contraseña incorrectos');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final logoAsset = themeMode == ThemeMode.dark ? 'assets/logoblanco.png' : 'assets/logo.png';
    const scaffoldBackgroundColor = Color(0xFF003056); // Fondo del Scaffold siempre azul

    final bool isDarkMode = themeMode == ThemeMode.dark;
    final containerBackgroundColor = isDarkMode ? const Color.fromARGB(75, 206, 206, 206) : Colors.white;
    // El color del texto del título principal dentro del contenedor será manejado por el Theme wrapper
    // final textColor = isDarkMode ? Colors.black87 : const Color(0xFF003056); // Ya no se usa directamente aquí

    const appBarIconColor = Colors.white;

    // Define el tema para el contenido del card
    // Si estamos en modo oscuro y el card es claro, usamos un tema claro para el contenido del card.
    // De lo contrario, usamos el tema actual del contexto.
    final ThemeData cardContentTheme = isDarkMode
        ? ThemeData.light().copyWith(
            // Puedes copiar aquí las fuentes u otras configuraciones específicas de tu tema claro principal si es necesario
            // Por ejemplo, para mantener GoogleFonts:
            // textTheme: GoogleFonts.robotoTextTheme(ThemeData.light().textTheme),
            colorScheme: ThemeData.light().colorScheme.copyWith(
                  primary: const Color(0xFF003056), // Color primario para elementos como el cursor, borde enfocado del TextField
                ),
            inputDecorationTheme: InputDecorationTheme(
              border: const OutlineInputBorder(),
              labelStyle: TextStyle(color: Colors.grey[700]), // Color para labels de TextField
              // Asegúrate que los colores de prefijos y sufijos también sean visibles
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.black), // Color para TextButton
            )
          )
        : Theme.of(context);

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: appBarIconColor),
          onPressed: () => Navigator.pushReplacementNamed(context, '/loaderScreen'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: containerBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Theme(
              data: cardContentTheme, // Aplicar el tema al contenido del card
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(logoAsset, height: 100),
                  const SizedBox(height: 20),
                  Text(
                    'Bienvenido de nuevo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.black87 : const Color(0xFF003056), // Color explícito para el título
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/recovery'),
                    child: const Text(
                      '¿Olvidaste tu contraseña?',
                      // El estilo del TextButton ahora se toma de cardContentTheme.textButtonTheme
                      // style: TextStyle(color: Colors.black), // Ya no es necesario aquí si se configura en TextButtonThemeData
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003056),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}