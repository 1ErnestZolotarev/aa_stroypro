import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  AppUser? _user;
  bool _isLoading = false;

  AppUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get currentPhone => _user?.phone;

  Future<void> loadUser(String phone) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.getCurrentUser(phone);
    } catch (e) {
      print('Error loading user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String phone, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.signIn(phone, password);
      if (_user != null) {
        await updateLastSeen(); // обновляем время последнего посещения
      }
    } catch (e) {
      print('Error signing in: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String phone,
    required String name,
    required String city,
    required String role,
    String? email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _user = await _authService.register(
        phone: phone,
        name: name,
        city: city,
        role: role,
        email: email,
        password: password,
      );
      if (_user != null) {
        await updateLastSeen();
      }
    } catch (e) {
      print('Error registering: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> updateProfile({required String name, required String city, required String role}) async {
    if (_user == null) return;
    try {
      final docId = _user!.phone.replaceAll(RegExp(r'\D'), '');
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'name': name,
        'city': city,
        'role': role,
      });
      _user = AppUser(
        phone: _user!.phone,
        name: name,
        city: city,
        role: role,
        uid: _user!.uid,
        isAdmin: _user!.isAdmin,
        bannedUntil: _user!.bannedUntil,
        lastSeen: _user!.lastSeen,
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  Future<void> updateLastSeen() async {
    if (_user == null) return;
    try {
      final docId = _user!.phone.replaceAll(RegExp(r'\D'), '');
      await FirebaseFirestore.instance.collection('users').doc(docId).update({
        'lastSeen': DateTime.now().toIso8601String(),
      });
      // обновляем локальный объект, чтобы не делать повторный запрос
      _user = AppUser(
        phone: _user!.phone,
        name: _user!.name,
        city: _user!.city,
        role: _user!.role,
        uid: _user!.uid,
        isAdmin: _user!.isAdmin,
        bannedUntil: _user!.bannedUntil,
        lastSeen: DateTime.now(),
        createdAt: _user!.createdAt,
      );
      notifyListeners();
    } catch (e) {
      print('Error updating lastSeen: $e');
    }
  }
}
