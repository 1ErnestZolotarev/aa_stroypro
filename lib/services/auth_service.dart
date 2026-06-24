import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Проверяет, существует ли пользователь с таким номером и привязан ли email
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final email = data['email'] as String?;
      if (email != null && email.isNotEmpty) {
        return {'exists': true, 'needsPassword': true, 'email': email};
      }
      return {'exists': true, 'needsPassword': false};
    }
    return {'exists': false, 'needsPassword': false};
  }

  /// Вход по номеру (без пароля) – только если email не привязан
  Future<AppUser?> signInWithPhone({
    required String name,
    required String phone,
    required String city,
    required String role,
  }) async {
    await _auth.signInAnonymously();
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final userRef = _firestore.collection('users').doc(docId);
    final existing = await userRef.get();
    if (existing.exists) {
      await userRef.update({
        'name': name,
        'city': city,
        'role': role,
      });
    } else {
      final newUser = AppUser(
        phone: phone,
        name: name,
        city: city,
        role: role,
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toMap());
    }
    final doc = await userRef.get();
    return AppUser.fromMap(doc.data()!);
  }

  /// Вход по email и паролю (для пользователей с привязанным email)
  Future<AppUser?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Ищем пользователя по email
    final snapshot = await _firestore.collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  /// Привязка email к существующему аккаунту (по номеру телефона)
  Future<void> linkEmail(String phone, String email, String password) async {
    // Создаём email-аккаунт
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    // Привязываем к текущему анонимному аккаунту
    await _auth.currentUser!.linkWithCredential(credential);
    // Отправляем письмо для подтверждения
    await _auth.currentUser!.sendEmailVerification();
    // Сохраняем email в профиле
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    await _firestore.collection('users').doc(docId).update({
      'email': email,
    });
  }

  /// Проверяет, подтверждён ли email у текущего пользователя
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getCurrentUser(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!);
    return null;
  }
}
