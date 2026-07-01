import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<bool> phoneExists(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    return doc.exists;
  }

  Future<String?> getEmailByPhone(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    final realEmail = data['email'] as String?;
    if (realEmail != null && realEmail.isNotEmpty) return realEmail;
    return '$docId@aa-stroypro.local';
  }

  Future<AppUser> register({
    required String phone,
    required String name,
    required String city,
    required String role,
    String? email,
    required String password,
  }) async { /* ... тело метода без изменений ... */ }

  Future<AppUser?> signIn(String phone, String password) async { /* ... */ }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}.${dt.month}.${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> banUser(String phone, int hours) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final bannedUntil = DateTime.now().add(Duration(hours: hours));
    await _firestore.collection('users').doc(docId).update({
      'bannedUntil': bannedUntil.toIso8601String(),
    });
  }

  Future<void> unbanUser(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    await _firestore.collection('users').doc(docId).update({
      'bannedUntil': '',
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getCurrentUser(String phone) async { /* ... */ }

  Future<void> updateEmail(String phone, String newEmail, String password) async { /* ... */ }
}
