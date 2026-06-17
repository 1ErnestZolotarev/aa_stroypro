import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();
  AppUser? _user;
  bool _loading = false;
  String? _error;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;

  AuthProvider() {
    _auth.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _auth.getCurrentUser();
        _error = null;
      } else {
        _user = null;
        _error = null;
      }
      notifyListeners();
    });
  }

  Future<void> registerAnonymous(
      String name, String phone, String city, String role) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _auth.signInAnonymously(name, phone, city, role);
    } catch (e) {
      _error = e.toString();
      debugPrint('Ошибка регистрации: $e');
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
