import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Проверяет, существует ли пользователь с таким номером.
  Future<bool> phoneExists(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    return doc.exists;
  }

  /// Получает email (реальный или фиктивный) по номеру телефона.
  Future<String?> getEmailByPhone(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    // Если указан реальный email, возвращаем его; иначе фиктивный.
    final realEmail = data['email'] as String?;
    if (realEmail != null && realEmail.isNotEmpty) return realEmail;
    return '$docId@aa-stroypro.local';
  }

  /// Регистрация нового пользователя (или обновление существующего без пароля).
  Future<AppUser> register({
    required String phone,
    required String name,
    required String city,
    required String role,
    String? email,
    required String password,
  }) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final authEmail = (email != null && email.isNotEmpty) ? email : '$docId@aa-stroypro.local';
    
    // Создаём или обновляем аккаунт Firebase Auth.
    try {
      // Попытка создать нового пользователя.
      await _auth.createUserWithEmailAndPassword(email: authEmail, password: password);
      if (email != null && email.isNotEmpty) {
        await _auth.currentUser?.sendEmailVerification();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Пользователь уже существует, пробуем войти с переданным паролем.
        await _auth.signInWithEmailAndPassword(email: authEmail, password: password);
      } else {
        rethrow;
      }
    }

    // Сохраняем или обновляем документ пользователя в Firestore.
    final userRef = _firestore.collection('users').doc(docId);
    final newUser = AppUser(
      phone: phone,
      name: name,
      city: city,
      role: role,
      createdAt: DateTime.now(),
    );
    await userRef.set(newUser.toMap(), SetOptions(merge: true));
    // Если указан реальный email, сохраняем его в документе для будущих входов.
    if (email != null && email.isNotEmpty) {
      await userRef.update({'email': email});
    }

    return newUser;
  }

  /// Вход по номеру телефона и паролю.
  Future<AppUser?> signIn(String phone, String password) async {
    final email = await getEmailByPhone(phone);
    if (email == null) return null;
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!);
    return null;
  }

  /// Выход.
  Future<void> signOut() => _auth.signOut();

  /// Получение данных пользователя по номеру.
  Future<AppUser?> getCurrentUser(String phone) async {
    final docId = phone.replaceAll(RegExp(r'\D'), '');
    final doc = await _firestore.collection('users').doc(docId).get();
    if (doc.exists) return AppUser.fromMap(doc.data()!);
    return null;
  }
  /// Обновляет email текущего пользователя после проверки пароля.
  Future<void> updateEmail(String phone, String newEmail, String password) async {
    final oldEmail = await getEmailByPhone(phone);
    if (oldEmail == null) throw Exception("Пользователь не найден");
    
    // Повторно аутентифицируем пользователя
    final credential = EmailAuthProvider.credential(email: oldEmail, password: password);
    await _auth.currentUser!.reauthenticateWithCredential(credential);
    
    // Обновляем email
    await _auth.currentUser!.verifyBeforeUpdateEmail(newEmail);
    
    // Сохраняем новый email в Firestore
    final docId = phone.replaceAll(RegExp(r"D"), "");
    await _firestore.collection("users").doc(docId).update({"email": newEmail});
  }
}
