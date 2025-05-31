import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:applensys/providers/text_size_provider.dart'; // Importar el provider
import 'package:applensys/providers/theme_provider.dart'; // Importar themeModeProvider

final recoveryControllerProvider =
    StateNotifierProvider<RecoveryController, AsyncValue<void>>(
  (ref) => RecoveryController(),
);

class RecoveryController extends StateNotifier<AsyncValue<void>> {
  RecoveryController() : super(const AsyncValue.data(null));

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncValue.loading();
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

class RecoveryScreen extends ConsumerStatefulWidget {
  const RecoveryScreen({super.key});

  @override
  ConsumerState<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends ConsumerState<RecoveryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _onSubmit() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(recoveryControllerProvider.notifier)
          .sendPasswordResetEmail(_emailController.text);
      if (!mounted) return;

      final state = ref.read(recoveryControllerProvider);
      state.whenOrNull(
        data: (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Correo enviado con éxito')),
          );
        },
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${err.toString()}')),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final recoveryState = ref.watch(recoveryControllerProvider);
    final textSize = ref.watch(textSizeProvider); // Obtener el tamaño de texto
    final double scaleFactor = textSize / 14.0; // Asumiendo 14.0 como tamaño base
    final themeMode = ref.watch(themeModeProvider); // Observar el themeModeProvider

    // Determinar el color de fondo del Scaffold basado en el tema
    final scaffoldBackgroundColor = themeMode == ThemeMode.dark
        ? const Color.fromARGB(75, 206, 206, 206) // Fondo gris para modo oscuro
        : Theme.of(context).scaffoldBackgroundColor; // Fondo del tema claro por defecto

    return Scaffold(
      backgroundColor: scaffoldBackgroundColor, // Aplicar color de fondo dinámico
      appBar: AppBar(
        title: Text('Recuperar contraseña', style: TextStyle(fontSize: 20 * scaleFactor, color: Colors.white)), // Texto siempre blanco
        toolbarHeight: kToolbarHeight * scaleFactor,
        backgroundColor: const Color(0xFF003056), // AppBar siempre azul
        iconTheme: const IconThemeData(color: Colors.white), // Icono de flecha siempre blanco
      ),
      body: Padding(
        padding: EdgeInsets.all(16 * scaleFactor), // Aplicar scaleFactor al padding
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Introduce tu correo para recibir el enlace de recuperación',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16 * scaleFactor), // Aplicar scaleFactor
              ),
              SizedBox(height: 16 * scaleFactor), // Aplicar scaleFactor
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(fontSize: 14 * scaleFactor), // Aplicar scaleFactor al texto de entrada
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  labelStyle: TextStyle(fontSize: 14 * scaleFactor), // Aplicar scaleFactor al label
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      !value.contains('@')) {
                    return 'Introduce un correo válido';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16 * scaleFactor), // Aplicar scaleFactor
              recoveryState.isLoading
                  ? SizedBox(
                      width: 24 * scaleFactor, // Escalar CircularProgressIndicator
                      height: 24 * scaleFactor,
                      child: const CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 20 * scaleFactor, vertical: 12 * scaleFactor), // Escalar padding del botón
                      ),
                      onPressed: _onSubmit,
                      child: Text('Enviar', style: TextStyle(fontSize: 16 * scaleFactor)), // Aplicar scaleFactor
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
