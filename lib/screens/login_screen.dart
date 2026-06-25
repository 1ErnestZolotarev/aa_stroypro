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
  final _phone = TextEditingController(), _password = TextEditingController();
  bool _showPassword = false;
  Timer? _debounce;

  @override
  void dispose() { _debounce?.cancel(); _phone.dispose(); _password.dispose(); super.dispose(); }

  void _onPhoneChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      setState(() => _showPassword = digits.length >= 11);
    });
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите пароль')));
      return;
    }
    try {
      await context.read<OurAuth.AuthProvider>().signIn(_phone.text, _password.text);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _forgotPassword() async {
    final phone = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (phone.length < 11) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите номер телефона')));
      return;
    }
    try {
      final email = await AuthService().getEmailByPhone(_phone.text);
      if (email == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь не найден')));
        return;
      }
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
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
      body: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone)),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          onChanged: (_) => _onPhoneChanged(),
        ),
        if (_showPassword) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock)),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _forgotPassword,
              child: const Text('Забыли пароль?'),
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: (a.loading || !_showPassword) ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: a.loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Войти', style: TextStyle(fontSize: 16)),
        )),
      ])),
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
