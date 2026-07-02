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
  }) async {
    try {
      // Создаем пользователя в Firebase Auth с email (если email не указан – создаем фейковый)
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email ?? '$phone@aa-stroypro.local',
        password: password,
      );
      final uid = userCredential.user!.uid;
      final docId = phone.replaceAll(RegExp(r'\D'), '');
      final now = DateTime.now();
      final user = AppUser(
        phone: phone,
        name: name,
        city: city,
        role: role,
        uid: uid,
        isAdmin: false,
        bannedUntil: null,
        lastSeen: now,
        createdAt: now,
      );
      await _firestore.collection('users').doc(docId).set(user.toMap());
      // дополнительно сохраним uid в поле для связи
      await _firestore.collection('users').doc(docId).update({'uid': uid});
      return user;
    } catch (e) {
      throw Exception('Ошибка регистрации: $e');
    }
  }

  Future<AppUser?> signIn(String phone, String password) async {
    try {
      final email = await getEmailByPhone(phone);
      if (email == null) return null;
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = userCredential.user!.uid;
      final docId = phone.replaceAll(RegExp(r'\D'), '');
      final doc = await _firestore.collection('users').doc(docId).get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final user = AppUser.fromMap(data);
      // обновляем lastSeen
      await _firestore.collection('users').doc(docId).update({
        'lastSeen': DateTime.now().toIso8601String(),
      });
      return user;
    } catch (e) {
      return null;
    }
  }

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

  Future<AppUser?> getCurrentUser(String phone) async {
    try {
      final docId = phone.replaceAll(RegExp(r'\D'), '');
      final doc = await _firestore.collection('users').doc(docId).get();
      if (!doc.exists) return null;
      return AppUser.fromMap(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateEmail(String phone, String newEmail, String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Пользователь не авторизован');
      // Проверка пароля (переаутентификация)
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updateEmail(newEmail);
      // обновляем в Firestore, если храним email
      final docId = phone.replaceAll(RegExp(r'\D'), '');
      await _firestore.collection('users').doc(docId).update({'email': newEmail});
    } catch (e) {
      throw Exception('Ошибка обновления email: $e');
    }
  }
}
