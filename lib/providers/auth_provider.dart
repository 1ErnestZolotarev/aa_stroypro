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

  // Номер телефона текущего пользователя (нужен для идентификации)
  String? _currentPhone;
  String? get currentPhone => _currentPhone;

  Future<void> signInWithPhone({
    required String name,
    required String phone,
    required String city,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _user = await _auth.signInWithPhone(
        name: name,
        phone: phone,
        city: city,
        role: role,
      );
      _currentPhone = phone;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    String? city,
    String? role,
  }) async {
    if (_user == null || _currentPhone == null) return;

    _loading = true;
    notifyListeners();

    try {
      final docId = _currentPhone!.replaceAll(RegExp(r'\D'), '');
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (role != null) 'role': role,
      });
      _user = AppUser(
        phone: _currentPhone!,
        name: name ?? _user!.name,
        city: city ?? _user!.city,
        role: role ?? _user!.role,
        createdAt: _user!.createdAt,
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _currentPhone = null;
    notifyListeners();
  }
}
