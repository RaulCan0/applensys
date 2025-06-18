import 'package:flutter/material.dart';
import 'package:applensys/services/domain/empresa_service.dart';
import 'package:applensys/models/empresa.dart';

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
      if (mounted) {
        setState(() {
          empresas = data;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar empresas: \$e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Historial de Empresas',
          style: TextStyle(fontSize: screenSize.width * 0.05),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEmpresas,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: empresas.length,
              itemBuilder: (context, index) {
                final empresa = empresas[index];
                return GestureDetector(
                  onTap: () {
                  
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            empresa.nombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Asociados: \${empresa.empleadosAsociados.length}'),
                            Text('Empleados: \${empresa.empleadosTotal}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
