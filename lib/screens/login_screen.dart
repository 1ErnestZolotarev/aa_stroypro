import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _city = TextEditingController(), _password = TextEditingController();
  String _role = 'customer';
  bool _needsPassword = false;
  String? _existingEmail;
  bool _checkingPhone = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _name.dispose();
    _phone.dispose();
    _city.dispose();
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

  Future<void> _submit() async {
    if (_f.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      if (_needsPassword) {
        if (_password.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите пароль')));
          return;
        }
        await auth.signInWithEmail(_existingEmail!, _password.text);
      } else {
        await auth.signInWithPhone(name: _name.text, phone: _phone.text, city: _city.text, role: _role);
      }
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

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Не удалось открыть ссылку')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(child: SingleChildScrollView(padding: const EdgeInsets.all(32), child: Form(key: _f, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 90,height: 90, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0,8))]), child: const Icon(Icons.construction, size: 50, color: Colors.white)),
        const SizedBox(height: 20),
        const Text('ААСтройПро', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange)),
        Text('Биржа отделочных работ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        const SizedBox(height: 32),
        if (a.error != null) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(a.error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center)),
        TextFormField(
          controller: _phone,
          decoration: InputDecoration(labelText: 'Телефон', prefixIcon: const Icon(Icons.phone, color: Colors.grey), hintText: '+7 (___) ___-__-__', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          onChanged: (_) => _checkPhone(),
          validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
        ),
        if (_checkingPhone) const Padding(padding: EdgeInsets.all(8), child: CircularProgressIndicator()),
        if (!_needsPassword && !_checkingPhone) ...[
          const SizedBox(height: 12),
          TextFormField(controller: _name, decoration: InputDecoration(labelText: 'Ваше имя', prefixIcon: const Icon(Icons.person, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white), inputFormatters: [CapitalizeFirstLetterFormatter()], validator: (v) => v!.isEmpty ? 'Введите имя' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _city, decoration: InputDecoration(labelText: 'Город', prefixIcon: const Icon(Icons.location_city, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white), inputFormatters: [CapitalizeFirstLetterFormatter()], validator: (v) => v!.isEmpty ? 'Введите город' : null),
          const SizedBox(height: 24),
          Row(children: [Expanded(child: _roleBtn('Я заказчик','customer')), const SizedBox(width: 24), Expanded(child: _roleBtn('Я исполнитель','executor'))]),
        ] else if (_needsPassword && !_checkingPhone) ...[
          const SizedBox(height: 12),
          Text('Введите пароль для входа', style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 12),
          TextFormField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: 'Пароль', prefixIcon: const Icon(Icons.lock, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white), validator: (v) => v!.isEmpty ? 'Введите пароль' : null),
          const SizedBox(height: 8),
          TextButton(onPressed: _forgotPassword, child: const Text('Забыли пароль?')),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: (a.loading || _checkingPhone) ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: a.loading ? const SizedBox(width:24,height:24,child: CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Text('Войти', style: TextStyle(fontSize:16)),
        )),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _openUrl('https://docs.google.com/document/d/16EVLtV3598kpLhCRE8U03EURlXDU5EyNdUB-QT5Y0HI/preview'),
          child: Text('Политика конфиденциальности', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openUrl('https://docs.google.com/document/d/1Xiiy-_FHSjNv-qcDvibxkA_wFEkTP7mOr4dqOFzZ1DY/preview'),
          child: Text('Пользовательское соглашение', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, decoration: TextDecoration.underline)),
        ),
      ])))),
    );
  }

  Widget _roleBtn(String text, String role) => GestureDetector(
    onTap: () => setState(() => _role = role),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: _role==role?FontWeight.w700:FontWeight.w400, color: _role==role?Colors.orange:Colors.grey.shade600)),
      const SizedBox(height: 6),
      Container(height: 2, color: _role==role?Colors.orange:Colors.transparent),
    ]),
  );
}

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue now) {
    if (now.text.isEmpty) return now;
    final words = now.text.split(' ').where((w) => w.isNotEmpty).map((w) => w.length==1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
    return TextEditingValue(text: words, selection: TextSelection.collapsed(offset: words.length));
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
