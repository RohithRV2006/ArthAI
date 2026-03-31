import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arth/auth_service.dart';
import 'package:arth/local_storage.dart';
import 'package:arth/user_model.dart';

enum AuthStep { login, profileSetup }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStep _step = AuthStep.login;
  bool _isLoading = false;
  String? _error;
  User? _user;

  AuthStep get step => _step;
  bool get isLoading => _isLoading;
  String? get error => _error;
  User? get user => _user;
  bool get isLoggedIn => _user != null;

  AuthProvider() {
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null) {
        _user = result.user;
        _step = AuthStep.profileSetup;

        if (_user != null) {
          final userModel = UserModel(
            userId: _user!.uid,
            name: _user!.displayName ?? 'Arth User',
            email: _user!.email ?? '',
            members: [],
            incomeSources: [],
          );
          await LocalStorage.saveUser(userModel);
        }

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.signInWithEmail(email: email, password: password);
      _user = result.user;
      _step = AuthStep.profileSetup;

      if (_user != null) {
        final userModel = UserModel(
          userId: _user!.uid,
          name: _user!.displayName ?? 'Arth User',
          email: _user!.email ?? email,
          members: [],
          incomeSources: [],
        );
        await LocalStorage.saveUser(userModel);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> registerWithEmail(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final result = await _authService.registerWithEmail(email: email, password: password);
      _user = result.user;
      _step = AuthStep.profileSetup;

      if (_user != null) {
        final userModel = UserModel(
          userId: _user!.uid,
          name: 'Arth User',
          email: _user!.email ?? email,
          members: [],
          incomeSources: [],
        );
        await LocalStorage.saveUser(userModel);
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _step = AuthStep.login;

    // 🔥 This is the core fix for the "Old Records" issue!
    // We completely wipe all local databases and caches on the phone.
    await LocalStorage.clearUser();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  void goBackToLogin() {
    _step = AuthStep.login;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}