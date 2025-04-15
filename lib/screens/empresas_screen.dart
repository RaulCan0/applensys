import 'package:applensys/screens/historial_screen.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import 'dimensiones_screen.dart';
import 'package:applensys/services/supabase_service.dart';

final supabaseService = SupabaseService();

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

class _EmpresasScreenState extends State<EmpresasScreen> {
  final List<Empresa> empresas = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEmpresas();
  }

  Future<void> _cargarEmpresas() async {
    try {
      final data = await supabaseService.getEmpresas();
      setState(() {
        empresas.clear();
        empresas.addAll(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error al cargar empresas: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final empresaCreada = empresas.isNotEmpty ? empresas.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Evaluación Empresarial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.indigo,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (empresaCreada != null)
              _buildButton(
                context,
                label: 'Evaluación de ${empresaCreada.nombre}',
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => DimensionesScreen(empresa: empresaCreada),
                      ),
                    ),
              ),
            const SizedBox(height: 20),
            _buildButton(
              context,
              label: 'HISTORIAL',
              onTap:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistorialScreen(empresas: empresas),
                    ),
                  ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaEmpresa(context),
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.indigo),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.chevron_right, color: Colors.indigo),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoNuevaEmpresa(BuildContext context) {
    final nombreController = TextEditingController();
    final empleadosController = TextEditingController();
    final unidadesController = TextEditingController();
    final areasController = TextEditingController();
    final sectorController = TextEditingController();
    String tamano = 'Pequeña';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text(
              'Registrar nueva empresa',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
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
                    controller: empleadosController,
                    decoration: const InputDecoration(
                      labelText: 'Total de empleados en la empresa',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: tamano,
                    items:
                        ['Pequeña', 'Mediana', 'Grande']
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (value) => tamano = value ?? 'Pequeña',
                    decoration: const InputDecoration(
                      labelText: 'Tamaño de la empresa',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: unidadesController,
                    decoration: const InputDecoration(
                      labelText: 'Unidades de negocio',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: areasController,
                    decoration: const InputDecoration(
                      labelText: 'Número de áreas',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: sectorController,
                    decoration: const InputDecoration(
                      labelText: 'Sector',
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
                  if (nombre.isNotEmpty) {
                    final nuevaEmpresa = Empresa(
                      id: const Uuid().v4(),
                      nombre: nombre,
                      tamano: tamano,
                      empleadosTotal:
                          int.tryParse(empleadosController.text.trim()) ?? 0,
                      empleadosAsociados: [],
                      unidades: unidadesController.text.trim(),
                      areas: int.tryParse(areasController.text.trim()) ?? 0,
                      sector: sectorController.text.trim(),
                    );

                    try {
                      await supabaseService.addEmpresa(nuevaEmpresa);
                      setState(() => empresas.add(nuevaEmpresa));
                      // ignore: use_build_context_synchronously
                      Navigator.pop(context);
                      debugPrint('✅ Empresa guardada en Supabase');
                    } catch (e) {
                      debugPrint('❌ Error al guardar empresa: $e');
                      if (mounted) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error al guardar empresa: $e'),
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                child: const Text(
                  'Guardar',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}
