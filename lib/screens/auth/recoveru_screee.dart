import 'package:applensys/services/remote/supabase_service.dart';
import 'package:flutter/material.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  void _showAlert(String title, String message, {bool closeOnOk = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (closeOnOk) Navigator.pop(context); // Vuelve atrás si se solicita
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<void> _recover() async {
    final email = _emailController.text.trim();
    // Validar formato de email
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (email.isEmpty || !emailRegex.hasMatch(email)) {
      _showAlert('Error', 'Ingresa un correo electrónico válido');
      return;
    }

    setState(() => _isLoading = true);
    final supabaseService = SupabaseService();
    final result = await supabaseService.resetPassword(email);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result['success'] == true) {
      _showAlert('Éxito', 'Se ha enviado un correo para restablecer la contraseña.', closeOnOk: true);
    } else {
      _showAlert('Error', result['message'] ?? 'No se pudo enviar el correo de recuperación');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar Contraseña'),
        backgroundColor: Colors.indigo,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Ingresa tu Correo electrónico',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _isLoading ? null : _recover,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.indigo,
                side: const BorderSide(color: Colors.indigo),
                backgroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
