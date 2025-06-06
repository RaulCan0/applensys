// register_screen.dart
import 'package:applensys/services/domain/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:applensys/providers/theme_provider.dart';
import 'package:applensys/screens/auth/login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
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

  Future<void> _register() async {
    // Validar formato de email
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(email)) {
      _showAlert('Error', 'Ingresa un correo electrónico válido');
      return;
    }

    if (_emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showAlert('Error', 'Completa todos los campos');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showAlert('Error', 'La contraseña debe tener al menos 6 caracteres');
      return;
    }

    // Confirmar contraseña
    if (_passwordController.text != _confirmPasswordController.text) {
      _showAlert('Error', 'Las contraseñas no coinciden');
      return;
    }

    setState(() => _isLoading = true);
    final supabaseService = SupabaseService();
    final result = await supabaseService.register(
      _emailController.text,
      _passwordController.text,
      _phoneController.text,
    );
    setState(() => _isLoading = false);

    if (result['success'] && mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Registro exitoso'),
          content: const Text(
            'Verifica tu correo electrónico en el enlace enviado para poder iniciar sesión.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } else {
      if (mounted) {
        _showAlert('Error', result['message'] ?? 'Error al registrarse');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ?Color(0xFF003056): const Color(0xFF003056);
    final scaffoldBackgroundColor = isDarkMode ? Color(0xFF003056) : primaryColor;
    final containerBackgroundColor = isDarkMode ? Colors.grey[850]! : Colors.white;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF003056);
    final hintTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];
    final iconColor = isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.grey[600];
    final logoAsset = isDarkMode ? 'assets/logoblanco.webp' : 'assets/logo.webp';
    final buttonTextColor = isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.white;
    final buttonBackgroundColor = isDarkMode ? Color(0xFF003056) : const Color.fromARGB(255, 255, 255, 255);
    final forgotPasswordColor = isDarkMode ? Color.fromARGB(255, 255, 255, 255): const Color.fromARGB(255, 255, 255, 255);


    return Scaffold(
      backgroundColor: scaffoldBackgroundColor, // Adaptado
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : Colors.white), // Adaptado
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(logoAsset, height: 100),
                const SizedBox(height: 20),
                Text(
                  'Crea tu cuenta',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo electrónico',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Número de teléfono',
                    prefixIcon: Icon(Icons.phone),
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
                const SizedBox(height: 16),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Confirmar contraseña',
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003056),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDarkMode
                            ? Colors.grey        // Dark theme: grey text
                            : const Color.fromARGB(255, 255, 255, 255), // Light theme: blue text
                        ),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}