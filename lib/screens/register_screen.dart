import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = 'customer';
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_f.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = context.read<OurAuth.AuthProvider>();
      // Регистрируем или входим по номеру телефона
      await auth.signInWithPhone(
        name: _name.text,
        phone: _phone.text,
        city: _city.text,
        role: _role,
      );

      // Если заполнены email и пароль — привязываем их
      if (_email.text.isNotEmpty && _password.text.isNotEmpty) {
        await AuthService().linkEmail(
          _phone.text,
          _email.text.trim(),
          _password.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация прошла успешно! Проверьте почту для подтверждения email.')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Регистрация прошла успешно!')),
          );
        }
      }
      // Возвращаемся на стартовый экран (после регистрации пользователь может сразу войти)
      if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _f,
          child: Column(
            children: [
              TextFormField(
                controller: _phone,
                decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                inputFormatters: [PhoneInputFormatter()],
                validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Имя', prefixIcon: Icon(Icons.person)),
                inputFormatters: [CapitalizeFirstLetterFormatter()],
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'Город', prefixIcon: Icon(Icons.location_city)),
                inputFormatters: [CapitalizeFirstLetterFormatter()],
                validator: (v) => v!.isEmpty ? 'Введите город' : null,
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _roleBtn('Я заказчик', 'customer')),
                const SizedBox(width: 24),
                Expanded(child: _roleBtn('Я исполнитель', 'executor')),
              ]),
              const SizedBox(height: 24),
              const Divider(),
              const Text('Дополнительно (для безопасности)', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email (необязательно)', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Пароль (необязательно)', prefixIcon: Icon(Icons.lock)),
              ),
              const SizedBox(height: 32),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Зарегистрироваться', style: TextStyle(fontSize: 16)),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleBtn(String text, String role) => GestureDetector(
        onTap: () => setState(() => _role = role),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: _role == role ? FontWeight.w700 : FontWeight.w400, color: _role == role ? Colors.orange : Colors.grey.shade600)),
          const SizedBox(height: 6),
          Container(height: 2, color: _role == role ? Colors.orange : Colors.transparent),
        ]),
      );
}

// Вспомогательные классы (можно вынести в отдельный файл, но для простоты оставим здесь)
class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue now) {
    if (now.text.isEmpty) return now;
    final words = now.text.split(' ').where((w) => w.isNotEmpty).map((w) => w.length == 1 ? w.toUpperCase() : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');
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
