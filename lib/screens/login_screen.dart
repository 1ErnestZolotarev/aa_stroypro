import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _needsPassword = false;
  String? _existingEmail;
  bool _checkingPhone = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkPhone() async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
      if (phone.length < 11) {
        setState(() { _needsPassword = false; _existingEmail = null; _checkingPhone = false; });
        return;
      }
      setState(() => _checkingPhone = true);
      try {
        final result = await AuthService().checkPhone(_phone.text);
        if (mounted) {
          setState(() {
            _needsPassword = result['needsPassword'] as bool;
            _existingEmail = result['email'] as String?;
          });
        }
      } finally {
        if (mounted) setState(() => _checkingPhone = false);
      }
    });
  }

  Future<void> _submitLogin() async {
    final auth = context.read<OurAuth.AuthProvider>();
    if (_needsPassword) {
      if (_password.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите пароль')));
        return;
      }
      await auth.signInWithEmail(_existingEmail!, _password.text);
      if (mounted) Navigator.pop(context);
    } else {
      // Номер существует, но без email – просто входим
      await auth.signInWithPhone(name: '', phone: _phone.text, city: '', role: 'customer');
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _forgotPassword() async {
    if (_existingEmail == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _existingEmail!);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Письмо для сброса пароля отправлено')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<OurAuth.AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Вход')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextFormField(
              controller: _phone,
              decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone)),
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneInputFormatter()],
              onChanged: (_) => _checkPhone(),
            ),
            if (_checkingPhone) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
            if (_needsPassword && !_checkingPhone) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _forgotPassword, child: const Text('Забыли пароль?')),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (a.loading || _checkingPhone) ? null : _submitLogin,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: a.loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Войти', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue now) {
    final digits = now.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    String f = '+7 ';
    if (digits.length > 1) f += '(${digits.substring(1, digits.length > 4 ? 4 : digits.length)}';
    if (digits.length > 4) f += ') ${digits.substring(4, digits.length > 7 ? 7 : digits.length)}';
    if (digits.length > 7) f += '-${digits.substring(7, digits.length > 9 ? 9 : digits.length)}';
    if (digits.length > 9) f += '-${digits.substring(9, digits.length > 11 ? 11 : digits.length)}';
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}
