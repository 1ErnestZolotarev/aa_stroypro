import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Пользователь уже существует – НЕ обновляем имя/город/роль
      // Просто возвращаем его данные
      return AppUser.fromMap(existing.data()!);
    } else {
      // Новый пользователь – создаём
      final newUser = AppUser(
        phone: phone,
        name: name,
        city: city,
        role: role,
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toMap());
      return newUser;
    }
  }

  Future<AppUser?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final snapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  Future<String> linkEmail(String phone, String email, String password) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('Пользователь не авторизован');

    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );

    try {
      await currentUser.linkWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw Exception('Этот email уже используется другим аккаунтом');
      } else if (e.code == 'invalid-email') {
        throw Exception('Некорректный email');
      } else if (e.code == 'weak-password') {
        throw Exception('Пароль слишком простой (минимум 6 символов)');
      }
      throw Exception('Ошибка: ${e.message}');
    }

    await currentUser.sendEmailVerification();

    final docId = phone.replaceAll(RegExp(r'\D'), '');
    await _firestore.collection('users').doc(docId).update({
      'email': email,
    });

    return 'Письмо для подтверждения отправлено на $email. Проверьте папку "Спам", если письма нет.';
  }

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getCurrentUser(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!);
    return null;
  }
}
