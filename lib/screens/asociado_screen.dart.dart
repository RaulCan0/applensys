import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Importar Supabase

import '../models/asociado.dart';
import '../../models/empresa.dart';
import 'principios_screen.dart';

class AsociadoScreen extends StatefulWidget {
  final Empresa empresa;
  final String dimensionId;

  const AsociadoScreen({
    super.key,
    required this.empresa,
    required this.dimensionId,
  });

  @override
  State<AsociadoScreen> createState() => _AsociadoScreenState();
}

class _AsociadoScreenState extends State<AsociadoScreen> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _antiguedadController = TextEditingController();
  String _cargo = 'ejecutivo';
  final supabase = Supabase.instance.client;

  Future<void> _agregarAsociado() async {
    final nombre = _nombreController.text.trim();
    final antiguedad = int.tryParse(_antiguedadController.text.trim());

    if (nombre.isEmpty || antiguedad == null) return;

    final nuevoId = const Uuid().v4();

    final response = await supabase.from('asociados').insert({
      'id': nuevoId,
      'nombre': nombre,
      'cargo': _cargo,
      'empresa_id': widget.empresa.id,
      'dimension_id': widget.dimensionId,
      'antiguedad': antiguedad,
    });

    if (response.error == null) {
      final nuevo = Asociado(
        id: nuevoId,
        nombre: nombre,
        cargo: _cargo,
        empresaId: widget.empresa.id,
      );

      setState(() {
        widget.empresa.empleadosAsociados.add(nuevo);
      });

      _nombreController.clear();
      _antiguedadController.clear();
    } else {
      // Manejo de error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${response.error!.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final asociadosEmpresa = widget.empresa.empleadosAsociados;

    return Scaffold(
      appBar: AppBar(
        title: Text('Asociados - ${widget.empresa.nombre}'),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del asociado',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _antiguedadController,
                            decoration: const InputDecoration(
                              labelText: 'Antigüedad (años)',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _cargo,
                            onChanged:
                                (value) => setState(() => _cargo = value!),
                            items:
                                ['ejecutivo', 'gerente', 'miembro de equipo']
                                    .map(
                                      (cargo) => DropdownMenuItem(
                                        value: cargo,
                                        child: Text(cargo.toUpperCase()),
                                      ),
                                    )
                                    .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Cargo',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _agregarAsociado,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                      ),
                      child: const Text(
                        'Asociar empleado',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Asociados:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: asociadosEmpresa.length,
                itemBuilder: (_, index) {
                  final asociado = asociadosEmpresa[index];
                  return Card(
                    child: ListTile(
                      title: Text(asociado.nombre),
                      subtitle: Text(asociado.cargo.toUpperCase()),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => PrincipiosScreen(
                                  empresa: widget.empresa,
                                  asociado: asociado,
                                  dimensionId: widget.dimensionId,
                                ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
