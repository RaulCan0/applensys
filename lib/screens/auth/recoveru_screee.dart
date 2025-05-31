import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uni_links/uni_links.dart';

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKeyFront = GlobalKey<FormState>();
  final _formKeyBack = GlobalKey<FormState>();
  bool isBackVisible = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    _listenToDeepLinks();
  }

  void _listenToDeepLinks() {
    uriLinkStream.listen((Uri? uri) async {
      if (uri != null &&
          uri.queryParameters['type'] == 'recovery' &&
          uri.queryParameters.containsKey('access_token')) {
        final token = uri.queryParameters['access_token']!;
        await Supabase.instance.client.auth.setSession(token);
        setState(() => isBackVisible = true);
        _controller.forward();
      }
    });
  }

  void _sendRecoveryEmail() async {
    if (_formKeyFront.currentState?.validate() ?? false) {
      try {
        await Supabase.instance.client.auth
            .resetPasswordForEmail(_emailController.text);
        _showSnackbar('Correo enviado con éxito');
      } catch (e) {
        _showSnackbar('Error: ${e.toString()}');
      }
    }
  }

  void _submitNewPassword() async {
    if (_formKeyBack.currentState?.validate() ?? false) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
        _showSnackbar('Contraseña actualizada con éxito');
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      } catch (e) {
        _showSnackbar('Error: ${e.toString()}');
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final angle = _controller.value * pi;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar contraseña'),
        backgroundColor: const Color(0xFF003056),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () {
            if (isBackVisible) {
              _controller.reverse();
              setState(() => isBackVisible = false);
            }
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final transform = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(angle);

              return Transform(
                transform: transform,
                alignment: Alignment.center,
                child: isBackVisible
                    ? _buildBackCard(context)
                    : _buildFrontCard(context),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKeyFront,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu correo para recuperar la contraseña',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo electrónico'),
                validator: (value) =>
                    value != null && value.contains('@') ? null : 'Correo inválido',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _sendRecoveryEmail,
                child: const Text('Enviar enlace'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard(BuildContext context) {
    return Card(
      elevation: 8,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKeyBack,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ingresa tu nueva contraseña',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nueva contraseña'),
                validator: (value) => value != null && value.length >= 6
                    ? null
                    : 'Mínimo 6 caracteres',
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitNewPassword,
                child: const Text('Actualizar contraseña'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
