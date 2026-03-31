import 'dart:convert';
import 'dart:math'; // 🔥 Added so we can generate random unique IDs
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/user_model.dart';

class LocalStorage {
  static const _keyUser = 'arth_user';
  static const _keyUserId = 'arth_user_id';

  // ── Save / load user ────────────────────────────────────────────────────
  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUser, jsonEncode(user.toJson()));
    await prefs.setString(_keyUserId, user.userId);
  }

  static Future<UserModel?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyUser);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw));
  }

  // 🔥 THE FIX: Auto-generates a unique ID if one doesn't exist yet!
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_keyUserId);

    // If there is no user ID (or it's an old test ID), generate a permanent unique one for this device
    if (userId == null || userId.isEmpty || userId == 'test_user') {
      userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
      await prefs.setString(_keyUserId, userId);
    }

    return userId;
  }

  static Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUser);
    await prefs.remove(_keyUserId);
  }

  // ── Language preference ──────────────────────────────────────────────────
  static Future<void> setLanguage(String lang) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('arth_language', lang);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('arth_language') ?? 'english';
  }
}