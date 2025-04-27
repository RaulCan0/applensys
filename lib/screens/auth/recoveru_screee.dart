import 'package:applensys/services/supabase_service.dart';
import 'package:flutter/material.dart';

class RecoveryScreen extends StatefulWidget {
  const RecoveryScreen({super.key});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  Future<void> _recover() async {
    setState(() => _isLoading = true);
    final supabaseService = SupabaseService();
    final success = await supabaseService.resetPassword(_emailController.text);
    setState(() => _isLoading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Correo enviado para restablecer contraseña'
              : 'Error al enviar correo',
        ),
      ),
    );
    if (success) Navigator.pop(context);
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
            const Text('Ingresa tu correo'),
            TextField(controller: _emailController),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _recover,
              child:
                  _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }
}
