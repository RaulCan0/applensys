import 'package:flutter/material.dart';
import 'package:applensys/services/domain/empresa_service.dart';
import 'package:applensys/models/empresa.dart';
import 'package:applensys/screens/resultados_historial_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importa la pantalla de resultados

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required List<Empresa> empresas, required List empresasHistorial});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final empresaService = EmpresaService();
  List<Empresa> empresas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final data = await empresaService.getEmpresas();
      setState(() {
        empresas = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al cargar empresas: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            'Historial de Empresas',
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: const Color(0xFF003056),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEmpresas,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : empresas.isEmpty
              ? const Center(child: Text('No hay empresas registradas.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: empresas.length,
                  itemBuilder: (context, index) {
                    final empresa = empresas[index];
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResultadosHistorialScreen(
                              empresa: empresa,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.business, color: Color(0xFF003056)),
                          title: Text(
                            empresa.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Color(0xFF003056)),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
