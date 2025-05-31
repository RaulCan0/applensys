import 'dart:io';
import 'package:applensys/providers/theme_provider.dart';
import 'package:applensys/services/domain/supabase_service.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:applensys/services/helpers/notification_service.dart';


class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _fotoUrl;
  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _cargarPerfil() async {
    setState(() => _loading = true);
    try {
      final data = await _supabaseService.getPerfil();
      if (data != null) {
        _nombreController.text = data['nombre'] ?? '';
        _emailController.text = data['email'] ?? '';
        _telefonoController.text = data['telefono'] ?? '';
        _fotoUrl = data['foto_url'];
      }
    } catch (e) {
      _showError('Error al cargar perfil: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _actualizarPerfil() async {
    setState(() => _loading = true);
    try {
      await _supabaseService.actualizarPerfil({
        'nombre': _nombreController.text.trim(),
        'email': _emailController.text.trim(),
        'telefono': _telefonoController.text.trim(),
        'foto_url': _fotoUrl,
      });

      if (_newPasswordController.text.isNotEmpty) {
        if (_newPasswordController.text != _confirmPasswordController.text) {
          _showError('Las nuevas contraseñas no coinciden.');
          setState(() => _loading = false);
          return;
        }
        await _supabaseService.actualizarContrasena(newPassword: _newPasswordController.text.trim());
        _newPasswordController.clear();
        _confirmPasswordController.clear();
        _showMessage('Perfil y contraseña actualizados correctamente.');
      } else {
        _showMessage('Perfil actualizado correctamente.');
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      _showError('Error al actualizar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _seleccionarFoto() async {
    String? path;
    if (Platform.isAndroid || Platform.isIOS) {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      path = picked.path;
    } else {
      final file = await openFile(
        acceptedTypeGroups: [
          XTypeGroup(label: 'images', extensions: ['jpg', 'jpeg', 'png']),
        ],
      );
      if (file == null) return;
      path = file.path;
    }
    try {
      final fileInBucket = await _supabaseService.subirFotoPerfil(path);
      final url = _supabaseService.getPublicUrl(
        bucket: 'profile_photos',
        path: fileInBucket,
      );
      setState(() => _fotoUrl = url);
      _showMessage('Foto actualizada');
    } catch (e) {
      _showError('Error al subir foto: $e');
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  void _showError(String err) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(err), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: const Color(0xFF003056),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                          child: _fotoUrl == null ? const Icon(Icons.person, size: 60) : null,
                        ),
                        GestureDetector(
                          onTap: _seleccionarFoto,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey.shade800,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(Icons.camera_alt, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nombreController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 24),
                  const Text('Cambiar Contraseña (opcional)', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Nueva Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar Contraseña',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                  ),
                  const SizedBox(height: 24),
                  const Text('Tema de la app', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('Auto'), icon: Icon(Icons.settings)),
                      ButtonSegment(value: ThemeMode.light, label: Text('Claro'), icon: Icon(Icons.light_mode)),
                      ButtonSegment(value: ThemeMode.dark, label: Text('Oscuro'), icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {current},
                    onSelectionChanged: (modes) {
                      final selected = modes.first;
                      themeNotifier.setTheme(selected);
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _actualizarPerfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003056),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Actualizar Perfil', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),const SizedBox(height: 12),
ElevatedButton.icon(
  icon: const Icon(Icons.notifications),
  label: const Text('Probar Notificación'),
  onPressed: () async {
    await NotificationService.showNotification(
      'Notificación de prueba',
      'Este es un mensaje de ejemplo desde PerfilScreen.',
      payload: 'perfil_test',
    );
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade700,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(vertical: 16),
  ),
),

                ],
              ),
            ),
    );
  }
}
