import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AppUser?> signInAnonymously(String name, String phone, String city,
      String role) async {
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
    return null;
  }

  /// Привязка email к текущему анонимному аккаунту
  Future<void> linkEmail(String email, String password) async {
    final credential = EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    await _auth.currentUser!.linkWithCredential(credential);
  }

  /// Вход по email и паролю (для восстановления аккаунта)
  Future<AppUser?> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
    }
    return null;
  }

  /// Проверяет, привязан ли email
  bool get hasEmailProvider {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((p) => p.providerId == 'password');
  }

  /// Получает email текущего пользователя (если привязан)
  String? get currentEmail => _auth.currentUser?.email;

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
