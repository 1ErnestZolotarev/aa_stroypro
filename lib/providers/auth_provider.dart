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
  bool _isBanned = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  String? get error => _error;
  bool get isBanned => _isBanned;

  AuthProvider() {
    _auth.authStateChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        _user = await _auth.getCurrentUser();
        _isBanned = _user?.isBanned ?? false;
        _error = null;
      } else {
        _user = null;
        _isBanned = false;
        _error = null;
      }
      notifyListeners();
    });
  }

  Future<void> signInWithPhone({
    required String name,
    required String phone,
    required String city,
    required String role,
  }) async {
    _loading = true;
    _error = null;
    _isBanned = false;
    notifyListeners();

    try {
      _user = await _auth.signInWithPhone(
        name: name,
        phone: phone,
        city: city,
        role: role,
      );
      _isBanned = _user?.isBanned ?? false;
    } catch (e) {
      _error = e.toString();
      if (e.toString().contains('заблокирован')) {
        _isBanned = true;
      }
    }

    _loading = false;
    notifyListeners();
  }

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
        isPro: _user!.isPro,
        ordersLimit: _user!.ordersLimit,
        isBanned: _user!.isBanned,
        bannedReason: _user!.bannedReason,
        createdAt: _user!.createdAt,
      );

      await _userService.updateUser(updatedUser);
      _user = updatedUser;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _user = null;
    _isBanned = false;
    notifyListeners();
  }
}
