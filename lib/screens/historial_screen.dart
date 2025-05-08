import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/resultados_historial_screen.dart';
import 'package:flutter/material.dart';

class HistorialScreen extends StatelessWidget {
  final List<Map<String, dynamic>> empresasHistorial;

  const HistorialScreen({super.key, required this.empresasHistorial, required List<Empresa> empresas});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: empresasHistorial.length,
        itemBuilder: (context, index) {
          final empresa = empresasHistorial[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ResultadosHistorialScreen(empresa: empresa, empresaId: '', empresaNombre: '',),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Colors.indigo.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.indigo, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      empresa['nombre'] ?? 'Empresa',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.indigo),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
