import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static const _keyEmail = 'auth_email';
  static const _keyPassword = 'auth_password';
  static const _keyUserId = 'auth_userId';

  Future<Map<String, dynamic>> register(String email, String password, String telefono) async {
    try {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'telefono': telefono},
      );
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _saveLocalCredentials(email, password, userId);
        return {'success': true};
      } else {
        return {'success': false, 'message': 'No se pudo obtener el ID del usuario.'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final userId = res.user?.id;
      if (userId != null) {
        await _saveLocalCredentials(email, password, userId);
        return {'success': true};
      } else {
        return {'success': false, 'message': 'No se pudo obtener el ID del usuario.'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<void> _saveLocalCredentials(String email, String password, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);
    await prefs.setString(_keyUserId, userId);
  }
}
