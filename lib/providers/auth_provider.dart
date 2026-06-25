import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _auth = AuthService();
  AppUser? _user;
  bool _loading = false;
  String? _error;
  String? _currentPhone;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  String? get currentPhone => _currentPhone;

  /// Регистрация.
  Future<void> register({
    required String phone,
    required String name,
    required String city,
    required String role,
    String? email,
    required String password,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _user = await _auth.register(phone: phone, name: name, city: city, role: role, email: email, password: password);
      _currentPhone = phone;
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  /// Вход по номеру и паролю.
  Future<void> signIn(String phone, String password) async {
    _loading = true; _error = null; notifyListeners();
    try {
      _user = await _auth.signIn(phone, password);
      _currentPhone = phone;
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  /// Обновление профиля.
  Future<void> updateProfile({String? name, String? city, String? role}) async {
    if (_user == null || _currentPhone == null) return;
    _loading = true; notifyListeners();
    try {
      final docId = _currentPhone!.replaceAll(RegExp(r'\D'), '');
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        if (name != null) 'name': name,
        if (city != null) 'city': city,
        if (role != null) 'role': role,
      });
      _user = AppUser(phone: _currentPhone!, name: name ?? _user!.name, city: city ?? _user!.city, role: role ?? _user!.role, createdAt: _user!.createdAt);
    } catch (e) { _error = e.toString(); }
    _loading = false; notifyListeners();
  }

  Future<void> logout() async { await _auth.signOut(); _user = null; _currentPhone = null; notifyListeners(); }
}
