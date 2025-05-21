import 'package:flutter/material.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/screens/tabla_registros.dart';

class DetallesEvaluacionScreen extends StatelessWidget {
  final Empresa empresa;
  final Evaluacion evaluacion;

  const DetallesEvaluacionScreen({
    super.key,
    required this.empresa,
    required this.evaluacion,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        title: Text('Detalles de Evaluación', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Empresa: ${empresa.nombre}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Fecha: ${evaluacion.fecha.toLocal()}'),
            const SizedBox(height: 8),
            Text('Asociado: ${evaluacion.asociadoId}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TablasDimensionScreen(
                      empresa: empresa,
                      evaluacionId: evaluacion.id,
                      empresaId: empresa.id,
                      dimension: '',
                      asociadoId: evaluacion.asociadoId,
                    ),
                  ),
                );
              },
              child: const Text('Ver Promedios por Dimensión'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TablasRegistrosScreen(
                      empresa: empresa,
                      evaluacionId: evaluacion.id,
                      empresaId: empresa.id,
                      dimension: '',
                      asociadoId: evaluacion.asociadoId,
                    ),
                  ),
                );
              },
              child: const Text('Ver Registros Detallados'),
            ),
          ],
        ),
      ),
    );
  }
}
