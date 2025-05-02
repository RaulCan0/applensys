import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/empresa.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key, required List<Empresa> empresas});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final _supabase = Supabase.instance.client;
  List<Empresa> empresas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final response = await _supabase.from('empresas').select();

      final List<Empresa> empresasCargadas =
          (response as List).map((item) {
            List<String> empleadosAsociados = [];
            if (item['empleados_asociados'] is List) {
              empleadosAsociados = List<String>.from(
                item['empleados_asociados'],
              );
            } else if (item['empleados_asociados'] is String &&
                item['empleados_asociados'].isNotEmpty) {
              try {
                empleadosAsociados = List<String>.from(
                  jsonDecode(item['empleados_asociados']),
                );
              } catch (_) {
                empleadosAsociados = [];
              }
            }
            return Empresa(
              id: item['id'] ?? '',
              nombre: item['nombre'] ?? '',
              tamano: item['tamano'] ?? '',
              empleadosTotal: item['empleados_total'] ?? 0,
              empleadosAsociados: empleadosAsociados,
              unidades: item['unidades'] ?? '',
              areas: item['areas'] ?? 0,
              sector: item['sector'] ?? '',
            );
          }).toList();

      setState(() {
        empresas = empresasCargadas;
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
        title: const Text(
          'Historial de Empresas',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.indigo,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
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
                    leading: const Icon(Icons.business, color: Colors.indigo),
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
                            const Text(
                              'Empleados asociados:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            empresa.empleadosAsociados.isEmpty
                                ? const Text('No hay empleados asociados')
                                : Column(
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
