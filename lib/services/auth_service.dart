import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Вход/регистрация по номеру телефона
  Future<AppUser?> signInWithPhone({
    required String name,
    required String phone,
    required String city,
    required String role,
  }) async {
    // 1. Анонимный вход (только для аутентификации, uid не важен)
    await _auth.signInAnonymously();

    // 2. Ключ документа – очищенный номер телефона
    final docId = phone.replaceAll(RegExp(r'\D'), ''); // 79991234567
    final userRef = _firestore.collection('users').doc(docId);

    // 3. Проверяем, существует ли уже такой пользователь
    final existing = await userRef.get();
    if (existing.exists) {
      // Обновляем имя/город, но сохраняем старые данные
      await userRef.update({
        'name': name,
        'city': city,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Новый пользователь
      final newUser = AppUser(
        phone: phone,
        name: name,
        city: city,
        role: role,
        createdAt: DateTime.now(),
      );
      await userRef.set(newUser.toMap());
    }

    // 4. Возвращаем актуальные данные пользователя
    final doc = await userRef.get();
    return AppUser.fromMap(doc.data()!);
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getCurrentUser(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!);
    return null;
  }
}
