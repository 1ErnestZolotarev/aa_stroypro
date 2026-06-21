import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class EmailScreen extends StatefulWidget {
  /// true = привязка, false = вход
  final bool isLinking;

  const EmailScreen({super.key, this.isLinking = true});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      if (widget.isLinking) {
        await auth.linkEmail(_emailCtrl.text, _passwordCtrl.text);
      } else {
        await auth.signInWithEmail(_emailCtrl.text, _passwordCtrl.text);
      }

      if (mounted) {
        if (auth.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: ${auth.error}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.isLinking ? 'Email привязан!' : 'Вход выполнен!')),
          );
          Navigator.pop(context);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isLinking ? 'Привязать Email' : 'Вход по Email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isLinking)
                const Text(
                  'Привяжите email, чтобы не потерять аккаунт при смене телефона.',
                  style: TextStyle(fontSize: 16),
                ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите email';
                  if (!v.contains('@')) return 'Некорректный email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordCtrl,
                decoration: const InputDecoration(
                  labelText: 'Пароль',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Введите пароль';
                  if (v.length < 6) return 'Минимум 6 символов';
                  return null;
                },
              ),
              const SizedBox(height: 24),
              auth.loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(widget.isLinking ? 'Привязать' : 'Войти'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
