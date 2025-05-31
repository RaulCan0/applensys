import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio de autenticación centralizado
class AuthService {
  // Claves para SharedPreferences
  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keyUserId = 'auth_userId';

  final SupabaseClient _client = Supabase.instance.client;

  /// Registra un nuevo usuario
  Future<Map<String, dynamic>> register(
      String email, String password, String telefono) async {
    try {
      await _client.auth.signUp(email: email, password: password, data: {'telefono': telefono});
      // Guardar credenciales localmente después de un registro exitoso
      final userId = _client.auth.currentUser?.id;
      if (userId != null) await _saveLocalCredentials(email, password, userId);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  /// Inicia sesión con email y contraseña
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await _client.auth.signInWithPassword(email: email, password: password);
      final userId = res.user?.id;
      if (userId != null) await _saveLocalCredentials(email, password, userId);
      return {'success': true};
    } on AuthException catch (e) {
      // Intento de login offline
      final ok = await _checkLocalCredentials(email, password);
      if (ok) return {'success': true, 'message': 'Login offline'};
      return {'success': false, 'message': e.message};
    } catch (e) {
      // Fallback offline
      final ok = await _checkLocalCredentials(email, password);
      if (ok) return {'success': true, 'message': 'Login offline'};
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  /// Envía correo de recuperación de contraseña
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return {'success': true};
    } on AuthException catch (e) {
      return {'success': false, 'message': e.message};
    } catch (e) {
      return {'success': false, 'message': 'Error desconocido: $e'};
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    // Esta función es la que se llamará desde RecoveryController.
    // Simplemente envuelve la llamada a resetPassword y maneja la lógica de éxito/error internamente si es necesario,
    // o simplemente propaga la excepción para que RecoveryController la maneje.
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Cierra la sesión
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyUserId);
    await _client.auth.signOut();
  }

  /// ID del usuario autenticado
  String? get userId => _client.auth.currentUser?.id;

  /// ID del usuario autenticado offline
  Future<String?> get userIdOffline async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserId);
  }

  Future<void> _saveLocalCredentials(String email, String password, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyUserId, userId);
  }

  Future<bool> _checkLocalCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_keyEmail);
    final savedPass = prefs.getString(_keyPassword);
    return email == savedEmail && password == savedPass;
  }
}
