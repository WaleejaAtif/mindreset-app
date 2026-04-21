import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSetupService {
  static const String _profileKey = 'user_profile';

  // SAVE USER QUIZ / PROFILE DATA
  static Future<void> saveProfileData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    String jsonData = jsonEncode(data);
    await prefs.setString(_profileKey, jsonData);
  }

  // LOAD SAVED DATA
  static Future<Map<String, dynamic>?> getProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    String? jsonData = prefs.getString(_profileKey);
    if (jsonData == null) return null;
    return jsonDecode(jsonData);
  }

  // CHECK COMPLETION
  static Future<bool> isProfileCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_profileKey);
  }

  // RESET PROFILE
  static Future<void> resetProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}
