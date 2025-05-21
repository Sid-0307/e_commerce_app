import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_commerce_app/core/models/user_model.dart';
import 'dart:convert';

class UserPersistence {
  static const String _userKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data to shared preferences
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toMap()));
    await prefs.setBool(_isLoggedInKey, true);
  }

  // Get user data from shared preferences
  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);

    if (userData != null) {
      final map = jsonDecode(userData);
      return UserModel.fromMap(map, map['uid'] ?? '');
    }
    return null;
  }


  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear user data on logout
  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.setBool(_isLoggedInKey, false);
  }
}