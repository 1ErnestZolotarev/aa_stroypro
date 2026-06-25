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
  bool _phoneExists = false;
  bool _checking = false;
  Timer? _debounce;

  @override
  void dispose() { _debounce?.cancel(); _phone.dispose(); _password.dispose(); super.dispose(); }

  Future<void> _checkPhone() async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 11) {
        setState(() { _phoneExists = false; _checking = false; });
        return;
      }
      setState(() => _checking = true);
      try {
        final exists = await AuthService().phoneExists(_phone.text);
        if (mounted) setState(() => _phoneExists = exists);
      } finally {
        if (mounted) setState(() => _checking = false);
      }
    });
  }

  Future<void> _submit() async {
    if (!_phoneExists) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Номер не зарегистрирован')));
      return;
    }
    if (_password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите пароль')));
      return;
    }
    final auth = context.read<OurAuth.AuthProvider>();
    await auth.signIn(_phone.text, _password.text);
    if (mounted && auth.user != null) Navigator.pop(context);
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
          onChanged: (_) => _checkPhone(),
        ),
        if (_checking) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
        if (_phoneExists && !_checking) ...[
          const SizedBox(height: 12),
          TextFormField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль', prefixIcon: Icon(Icons.lock))),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: (a.loading || _checking) ? null : _submit,
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
