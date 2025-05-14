import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_selector/file_selector.dart';
import 'package:applensys/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final SupabaseService supabaseService = SupabaseService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _contrasenaController = TextEditingController();
  final TextEditingController _confirmarController = TextEditingController();

  String? _fotoUrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _loading = true);
    final data = await supabaseService.getPerfil();
    if (data != null) {
      _nombreController.text = data['nombre'] ?? '';
      _emailController.text = data['email'] ?? '';
      _telefonoController.text = data['telefono'] ?? '';
      _fotoUrl = data['foto_url'];
    }
    setState(() => _loading = false);
  }

  Future<void> _actualizarPerfil() async {
    try {
      // Actualizar datos en tabla perfil
      await supabaseService.actualizarPerfil({
        'nombre': _nombreController.text,
        'email': _emailController.text,
        'telefono': _telefonoController.text,
        'foto_url': _fotoUrl,
      });

      // Cambiar contraseña si se ingresó
      final nueva = _contrasenaController.text.trim();
      final confirmar = _confirmarController.text.trim();

      if (nueva.isNotEmpty || confirmar.isNotEmpty) {
        if (nueva != confirmar) {
          _mostrarError("Las contraseñas no coinciden");
          return;
        }
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(password: nueva),
        );
        _mostrarMensaje("Contraseña actualizada");
      }

      _mostrarMensaje("Perfil actualizado correctamente");
    } catch (e) {
      _mostrarError("Error al actualizar: $e");
    }
  }

  Future<void> _seleccionarFoto() async {
    String? path;

    if (Platform.isAndroid || Platform.isIOS) {
      final ImagePicker picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;
      path = pickedFile.path;
    } else {
      final XFile? file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
        ],
      );
      if (file == null) return;
      path = file.path;
    }

    try {
      final url = await supabaseService.subirFotoPerfil(path);
      setState(() => _fotoUrl = url);
      _mostrarMensaje("Foto actualizada");
    } catch (e) {
      _mostrarError("Error al subir foto: $e");
    }
  }

  void _mostrarMensaje(String mensaje) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  void _mostrarError(String error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundImage:
                              _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                          child:
                              _fotoUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: _seleccionarFoto,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade800,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _seleccionarFoto,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 35, 47, 112),
                      ),
                      child: const Text('Subir Foto de Perfil'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: "Nombre"),
                    ),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: "Correo"),
                    ),
                    TextField(
                      controller: _telefonoController,
                      decoration: const InputDecoration(labelText: "Teléfono"),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 32),
                    const Text(
                      "Cambiar Contraseña",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contrasenaController,
                      decoration: const InputDecoration(
                        labelText: "Nueva contraseña",
                      ),
                      obscureText: true,
                    ),
                    TextField(
                      controller: _confirmarController,
                      decoration: const InputDecoration(
                        labelText: "Confirmar contraseña",
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Actualizar Perfil"),
                      onPressed: _actualizarPerfil,
                    ),
                  ],
                ),
              ),
    );
  }
}
