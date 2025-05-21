import 'package:flutter/material.dart';
import 'package:applensys/main.dart';

/// Pantalla de error global para mostrar cualquier excepción no capturada
class ErrorScreen extends StatelessWidget {
  final Object error;
  final StackTrace stackTrace;

  const ErrorScreen({super.key, required this.error, required this.stackTrace});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('¡Algo salió mal!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Se ha producido un error inesperado.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.black87),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // Reinicia la app desde la raíz
                  runApp(const MyApp());
                },
                child: const Text('Reiniciar Aplicación'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
