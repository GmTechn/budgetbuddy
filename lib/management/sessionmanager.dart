import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyCurrentUser = "current_user_email";

  //Saving users info

  static Future<void> saveCurrentUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCurrentUser, email);
  }

  //Charging user's information
  static Future<String?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCurrentUser);
  }

  //Deleting user session
  static Future<void> clearCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
  }
}
