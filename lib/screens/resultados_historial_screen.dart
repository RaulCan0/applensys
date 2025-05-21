import 'package:applensys/screens/tabla_registros.dart';
import 'package:flutter/material.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/tablas_screen.dart';
import 'package:applensys/models/evaluacion.dart';
import 'package:applensys/services/remote/supabase_service.dart';
import 'package:applensys/screens/detalles_evaluacion_screen.dart';

class ResultadosHistorialScreen extends StatefulWidget {
  final Empresa empresa;

  const ResultadosHistorialScreen({
    super.key,
    required this.empresa,
  });

  @override
  State<ResultadosHistorialScreen> createState() => _ResultadosHistorialScreenState();
}

class _ResultadosHistorialScreenState extends State<ResultadosHistorialScreen> {
  bool isLoading = true;
  String? error;
  List<Evaluacion> evaluaciones = [];

  @override
  void initState() {
    super.initState();
    _cargarEvaluaciones();
  }

  Future<void> _cargarEvaluaciones() async {
    try {
      final supabaseService = SupabaseService();
      final data = await supabaseService.getEvaluacionesPorEmpresa(widget.empresa.id);
      setState(() {
        evaluaciones = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $error')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Historial: ${widget.empresa.nombre}', style: const TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: evaluaciones.isEmpty
          ? const Center(child: Text('No hay evaluaciones registradas.'))
          : ListView.builder(
              itemCount: evaluaciones.length,
              itemBuilder: (context, index) {
                final evaluacion = evaluaciones[index];
                return ListTile(
                  title: Text('Evaluación del ${evaluacion.fecha.toLocal()}'),
                  subtitle: Text('Asociado: ${evaluacion.asociadoId}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetallesEvaluacionScreen(
                          empresa: widget.empresa,
                          evaluacion: evaluacion,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
