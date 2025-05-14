import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResultadosHistorialScreen extends StatefulWidget {
  final String empresaId;
  final String empresaNombre;

  const ResultadosHistorialScreen({
    super.key,
    required this.empresaId,
    required this.empresaNombre, required Map<String, dynamic> empresa,
  });

  @override
  State<ResultadosHistorialScreen> createState() => _ResultadosHistorialScreenState();
}

class _ResultadosHistorialScreenState extends State<ResultadosHistorialScreen> {
  final _supabase = Supabase.instance.client;
  bool isLoading = true;
  Map<String, dynamic>? data;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarResultados();
  }

  Future<void> _cargarResultados() async {
    try {
      final respuesta = await _supabase
          .from('resultados')
          .select()
          .eq('empresa_id', widget.empresaId)
          .single();

      setState(() {
        data = respuesta;
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
    return Scaffold(
      appBar: AppBar(
        title: Text('Resultados: ${widget.empresaNombre}'),
        backgroundColor: Color.fromARGB(255, 35, 47, 112),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : _buildContenido(),
    );
  }

  Widget _buildContenido() {
    final evidencias = List<String>.from(data!['evidencias'] ?? []);
    final resultadosResumen = data!['resumen'] ?? '';
    final avancePorcentaje = data!['avance'] ?? 0;
    final promedioDim1 = data!['promedio_dim1'] ?? 0;
    final promedioDim2 = data!['promedio_dim2'] ?? 0;
    final promedioDim3 = data!['promedio_dim3'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Evidencias:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...evidencias.map((e) => Text('- $e')),
          const SizedBox(height: 16),
          const Text('Resultados:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(resultadosResumen),
          const SizedBox(height: 16),
          const Text('Avances:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('$avancePorcentaje% completado'),
          const SizedBox(height: 16),
          const Text('Promedios:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Dimensión 1: $promedioDim1'),
          Text('Dimensión 2: $promedioDim2'),
          Text('Dimensión 3: $promedioDim3'),
        ],
      ),
    );
  }
}
