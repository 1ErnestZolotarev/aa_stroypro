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
