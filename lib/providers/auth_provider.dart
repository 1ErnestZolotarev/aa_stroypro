import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();
  final UserService _userService = UserService();
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

  /// Обновление профиля
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? city,
    String? role,
  }) async {
    if (_user == null) return;

    _loading = true;
    notifyListeners();

    try {
      final updatedUser = AppUser(
        uid: _user!.uid,
        name: name ?? _user!.name,
        phone: phone ?? _user!.phone,
        city: city ?? _user!.city,
        role: role ?? _user!.role,
        avatarUrl: _user!.avatarUrl,
        createdAt: _user!.createdAt,
      );

      await _userService.updateUser(updatedUser);
      _user = updatedUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
      debugPrint('Ошибка обновления профиля: $e');
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
