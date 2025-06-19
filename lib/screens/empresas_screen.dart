// ignore_for_file: use_build_context_synchronously

import 'package:applensys/screens/dashboard_screen.dart';
import 'package:applensys/screens/historial_screen.dart';
import 'package:applensys/services/domain/empresa_service.dart';
import 'package:applensys/widgets/chat_screen.dart';
import 'package:applensys/widgets/drawer_lensys.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/empresa.dart';
import 'dimensiones_screen.dart';

// Servicio para empresas
final empresaService = EmpresaService();

class EmpresasScreen extends StatefulWidget {
  const EmpresasScreen({super.key});

  @override
  State<EmpresasScreen> createState() => _EmpresasScreenState();
}

// NOTA SOBRE RealtimeSubscribeException:
// Si encuentras "RealtimeSubscribeException: Realtime was unable to connect to the project database",
// verifica la configuración de REPLICACIÓN en tu panel de Supabase (Database > Replication).
// Las tablas deben estar añadidas a la publicación para que Realtime funcione.

class _EmpresasScreenState extends State<EmpresasScreen> {
  final List<Empresa> empresas = [];
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String correoUsuario = '';

  @override
  void initState() {
    super.initState();
    _verificarNuevoUsuario();
    _cargarEmpresas();
    _obtenerCorreoUsuario();
  }

  Future<void> _verificarNuevoUsuario() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final existe = await Supabase.instance.client
        .from('usuarios')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (existe == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('¡Bienvenido a LensysApp!'),
          content: const Text('¿Aceptas los términos y condiciones para continuar?'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await Supabase.instance.client.auth.signOut();
              },
              child: const Text('No aceptar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final nombre = user.userMetadata?['nombre'] ?? 'Usuario';
                final telefono = user.userMetadata?['telefono'] ?? '';

                await Supabase.instance.client.from('usuarios').insert({
                  'id': user.id,
                  'email': user.email,
                  'nombre': nombre,
                  'telefono': telefono,
                }).then((_) {
                  Navigator.pop(context);
                }).catchError((e) {
                  debugPrint('❌ Error al insertar usuario: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al guardar usuario: $e')),
                  );
                });
              },
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _obtenerCorreoUsuario() async {
    final session = Supabase.instance.client.auth.currentUser;
    setState(() {
      correoUsuario = session?.email ?? 'Usuario';
    });
  }

  Future<void> _cargarEmpresas() async {
    try {
      final data = await empresaService.getEmpresas();
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
    final screenSize = MediaQuery.of(context).size;
    final empresaCreada = empresas.isNotEmpty ? empresas.last : null;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(width: 300, child: const ChatWidgetDrawer()),
      endDrawer: DrawerLensys(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF003056),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.message, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text(
          'LensysApp',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido: $correoUsuario',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (correoUsuario == 'sistemas@lensys.com.mx')
                    ElevatedButton.icon(
                      icon: const Icon(Icons.science),
                      label: const Text('Modo pruebas: Usar/Cargar empresa'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _mostrarDialogoEmpresaPruebas,
                    ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (empresaCreada != null)
                          _buildButton(
                            context,
                            label: 'Evaluación de ${empresaCreada.nombre}',
                          // al navegar a DimensionesScreen…
                            onTap: () {
                              final String nuevaEvaluacionId = const Uuid().v4(); // Generar ID único para nueva evaluación
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => DimensionesScreen(
                                    empresa: empresaCreada,
                                    evaluacionId: nuevaEvaluacionId, // Usar el nuevo ID
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                        _buildButton(
                          context,
                          label: 'HISTORIAL',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HistorialScreen(
                                empresas: empresas,
                                empresasHistorial: [],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarDialogoNuevaEmpresa(context),
                backgroundColor: const Color(0xFF003056),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(100),
        ),
        elevation: 8,
        child: const Icon(Icons.add, size: 25, color: Colors.white),
      ),
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required VoidCallback onTap}) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF003056)),
          borderRadius: BorderRadius.circular(12),
          color: isDarkMode ? Colors.grey[700] : Colors.grey[200], // Color de fondo del contenedor
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 20),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)), // Color de texto del botón
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.chevron_right, color: Color(0xFF003056)),
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
      builder: (_) => AlertDialog(
        title: const Text('Registrar nueva empresa',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: nombreController,
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: empleadosController,
                decoration: const InputDecoration(
                    labelText: 'Total de empleados en la empresa', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: tamano,
                items: ['Pequeña', 'Mediana', 'Grande']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
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
                  empleadosTotal: int.tryParse(empleadosController.text.trim()) ?? 0,
                  empleadosAsociados: [],
                  unidades: unidadesController.text.trim(),
                  areas: int.tryParse(areasController.text.trim()) ?? 0,
                  sector: sectorController.text.trim(),
                  createdAt: DateTime.now(),
                );

                try {
                  await empresaService.addEmpresa(nuevaEmpresa);
                  if (!mounted) return;
                  setState(() => empresas.add(nuevaEmpresa));
                  Navigator.pop(context);
                } catch (e) {
                  debugPrint('❌ Error al guardar empresa: $e');
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('Error al guardar empresa: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
            child: const Text('Guardar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEmpresaPruebas() {
    // Implementa el diálogo para seleccionar o cargar una empresa de pruebas
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar empresa de pruebas'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Aquí puedes listar las empresas de pruebas disponibles
                // Por ejemplo, usando ListTile para cada empresa
                ListTile(
                  title: const Text('Empresa Prueba 1'),
                  onTap: () {
                    // Lógica para usar la empresa de prueba 1
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Empresa Prueba 2'),
                  onTap: () {
                    // Lógica para usar la empresa de prueba 2
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
}