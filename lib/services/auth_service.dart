import 'package:shared_preferences/shared_preferences.dart';

class AuthService {

  // 🔹 Save "remember me"
  static Future<void> saveRemember(String email, bool remember) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('remember', remember);

    if (remember) {
      await prefs.setString('email', email);
    } else {
      await prefs.remove('email');
    }
  }

  // 🔹 Get saved email
  static Future<String?> getRememberEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('email');
  }

  // 🔹 Check if remember is enabled
  static Future<bool> isRemembered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('remember') ?? false;
  }

  // 🔹 Fake login validation
  static Future<bool> signIn(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // ✅ Gmail validation (fixed regex)
    final emailRegex = RegExp(r'^[\w\.\-]+@gmail\.com$');

    if (!emailRegex.hasMatch(email)) {
      return false;
    }

    if (password.length < 6) {
      return false;
    }

    return true;
  }

  // 🔹 Logout
  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('email');
    await prefs.setBool('remember', false);
  }
}