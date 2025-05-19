import 'package:shared_preferences/shared_preferences.dart';

class Users {
  static Future<void> saveSession(String userId, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', userId);
    await prefs.setString('userName', userName);
    await prefs.setBool('isLogged', true);
  }

  static Future<Map<String, dynamic>?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final isLogged = prefs.getBool('isLogged') ?? false;
    if (!isLogged) return null;
    return {
      'userId': prefs.getString('userId'),
      'userName': prefs.getString('userName'),
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}