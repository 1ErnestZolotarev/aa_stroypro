import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Поиск пользователя по номеру телефона
  Future<AppUser?> getUserByPhone(String phone) async {
    final snapshot = await _firestore
        .collection('users')
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return AppUser.fromMap(snapshot.docs.first.data());
    }
    return null;
  }

  /// Вход/регистрация по номеру телефона
  Future<AppUser?> signInWithPhone({
    required String name,
    required String phone,
    required String city,
    required String role,
  }) async {
    // Проверяем, существует ли пользователь с таким телефоном
    final existingUser = await getUserByPhone(phone);
    
    if (existingUser != null) {
      // Проверяем, не забанен ли
      if (existingUser.isBanned) {
        throw Exception('Аккаунт заблокирован: ${existingUser.bannedReason ?? "Причина не указана"}');
      }
      
      // Обновляем данные существующего пользователя
      final updatedUser = AppUser(
        uid: existingUser.uid,
        name: name,
        phone: phone,
        city: city,
        role: role,
        avatarUrl: existingUser.avatarUrl,
        isPro: existingUser.isPro,
        ordersLimit: existingUser.ordersLimit,
        isBanned: existingUser.isBanned,
        bannedReason: existingUser.bannedReason,
        createdAt: existingUser.createdAt,
      );
      
      await _firestore.collection('users').doc(existingUser.uid).update(updatedUser.toMap());
      
      // Входим анонимно (телефонная аутентификация требует Blaze)
      // Сохраняем UID существующего пользователя
      final credential = await _auth.signInAnonymously();
      return updatedUser;
    } else {
      // Создаём нового пользователя
      final credential = await _auth.signInAnonymously();
      final user = credential.user;
      
      if (user != null) {
        final appUser = AppUser(
          uid: user.uid,
          name: name,
          phone: phone,
          city: city,
          role: role,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
        return appUser;
      }
    }
    return null;
  }

  /// Бан пользователя (только для админа)
  Future<void> banUser(String uid, String reason) async {
    await _firestore.collection('users').doc(uid).update({
      'isBanned': true,
      'bannedReason': reason,
    });
  }

  /// Разбан пользователя
  Future<void> unbanUser(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'isBanned': false,
      'bannedReason': '',
    });
  }

  Future<void> signOut() => _auth.signOut();

  Future<AppUser?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) return AppUser.fromMap(doc.data()!);
    }
    return null;
  }
}
