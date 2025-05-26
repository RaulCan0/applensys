import 'dart:convert';
import 'package:applensys/services/domain/empresa_service.dart';
import 'package:flutter/material.dart';
import '../models/empresa.dart';

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
        title: const Text('Historial de Empresas'),
                backgroundColor: const Color(0xFF003056),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarEmpresas,
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : empresas.isEmpty
              ? const Center(child: Text('No hay empresas registradas.'))
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: empresas.length,
                itemBuilder: (context, index) {
                  final empresa = empresas[index];
                  return ExpansionTile(
                    leading: const Icon(Icons.business, color: Color(0xFF003056)),
                    title: Text(
                      empresa.nombre,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('Tamaño', empresa.tamano),
                            _infoRow('Sector', empresa.sector),
                            _infoRow('Unidades', empresa.unidades),
                            _infoRow('Áreas', empresa.areas.toString()),
                            _infoRow(
                              'Empleados',
                              empresa.empleadosTotal.toString(),
                            ),
                            const SizedBox(height: 8),
                           
                          
                                 Column(
                                  children:
                                      empresa.empleadosAsociados
                                          .map(
                                            (empleado) => Padding(
                                              padding: const EdgeInsets.only(
                                                left: 8.0,
                                                top: 4.0,
                                              ),
                                              child: Text('• $empleado'),
                                            ),
                                          )
                                          .toList(),
                                ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
