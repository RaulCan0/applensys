import 'package:applensys/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/asociado.dart';
import '../models/empresa.dart';
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
  final supabase = Supabase.instance.client;
  final SupabaseService _supabaseService = SupabaseService();
  List<Asociado> asociados = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _cargarAsociados();
  }

  Future<void> _cargarAsociados() async {
    try {
      final asociadosCargados = await _supabaseService.getAsociadosPorEmpresa(
        widget.empresa.id,
      );
      setState(() {
        asociados = asociadosCargados;
      });
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(content: Text('Error al cargar asociados: $e')),
      );
    }
  }

  Future<void> _mostrarDialogoAgregarAsociado() async {
    final nombreController = TextEditingController();
    final antiguedadController = TextEditingController();
    String cargoSeleccionado = 'Ejecutivo';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nuevo Asociado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: antiguedadController,
                decoration: const InputDecoration(
                  labelText: 'Antigüedad (años)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: cargoSeleccionado,
                items: ['Ejecutivo', 'Gerente', 'Miembro'].map((nivel) {
                  return DropdownMenuItem<String>(
                    value: nivel,
                    child: Text(nivel),
                  );
                }).toList(),
                onChanged: (value) {
                  cargoSeleccionado = value!;
                },
                decoration: const InputDecoration(
                  labelText: 'Nivel',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nombreController.text.trim();
              final antiguedadTexto = antiguedadController.text.trim();
              final antiguedad = int.tryParse(antiguedadTexto);

              if (nombre.isEmpty || antiguedad == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Completa todos los campos correctamente.')),
                );
                return;
              }

              final nuevoId = const Uuid().v4();
              final nuevo = Asociado(
                id: nuevoId,
                nombre: nombre,
                cargo: cargoSeleccionado.toLowerCase(),
                empresaId: widget.empresa.id,
                empleadosAsociados: [],
                progresoDimensiones: {},
                comportamientosEvaluados: {},
                antiguedad: antiguedad,
              );

              try {
                await supabase.from('asociados').insert({
                  'id': nuevoId,
                  'nombre': nombre,
                  'cargo': cargoSeleccionado.toLowerCase(),
                  'empresa_id': widget.empresa.id,
                  'dimension_id': widget.dimensionId,
                  'antiguedad': antiguedad,
                });

                setState(() {
                  asociados.add(nuevo);
                });

                if (mounted) Navigator.pop(context);

                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Asociado agregado exitosamente')),
                );
              } catch (e) {
                if (mounted) Navigator.pop(context);
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Error al guardar asociado: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: const Text('Asociar empleado'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Asociados - ${widget.empresa.nombre}'),
          backgroundColor: Colors.indigo,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: asociados.isEmpty
              ? const Center(child: Text('No hay asociados registrados'))
              : ListView.builder(
                  itemCount: asociados.length,
                  itemBuilder: (context, index) {
                    final asociado = asociados[index];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_outline, color: Colors.indigo),
                        title: Text(asociado.nombre),
                        subtitle: Text('${asociado.cargo.toUpperCase()} - ${asociado.antiguedad} años'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrincipiosScreen(
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
        floatingActionButton: FloatingActionButton(
          onPressed: _mostrarDialogoAgregarAsociado,
          backgroundColor: Colors.indigo,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          elevation: 8,
          child: const Icon(Icons.person_add_alt_1, size: 32, color: Colors.white),
        ),
      ),
    );
  }
}