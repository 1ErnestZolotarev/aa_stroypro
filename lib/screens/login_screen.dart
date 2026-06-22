import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _role = 'customer';

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.construction, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('ААСтройПро', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orange)),
                const SizedBox(height: 6),
                Text('Биржа отделочных работ', style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 32),
                if (auth.isBanned)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.block, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Ваш аккаунт заблокирован.\n${auth.error ?? ""}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Ваше имя', prefixIcon: const Icon(Icons.person, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => v!.isEmpty ? 'Введите имя' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: InputDecoration(
                    labelText: 'Телефон', prefixIcon: const Icon(Icons.phone, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _cityCtrl,
                  decoration: InputDecoration(
                    labelText: 'Город', prefixIcon: const Icon(Icons.location_city, color: Colors.grey),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true, fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  validator: (v) => v!.isEmpty ? 'Введите город' : null,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'customer'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Я заказчик', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: _role == 'customer' ? FontWeight.w700 : FontWeight.w400,
                                color: _role == 'customer' ? Colors.orange : Colors.grey.shade600)),
                            const SizedBox(height: 6),
                            Container(height: 2, color: _role == 'customer' ? Colors.orange : Colors.transparent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _role = 'executor'),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Я исполнитель', textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, fontWeight: _role == 'executor' ? FontWeight.w700 : FontWeight.w400,
                                color: _role == 'executor' ? Colors.orange : Colors.grey.shade600)),
                            const SizedBox(height: 6),
                            Container(height: 2, color: _role == 'executor' ? Colors.orange : Colors.transparent),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (auth.error != null && !auth.isBanned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                      child: Text(auth.error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center),
                    ),
                  ),
                SizedBox(
                  width: double.infinity, height: 50,
                  child: ElevatedButton(
                    onPressed: auth.loading || auth.isBanned ? null : () async {
                      if (_formKey.currentState!.validate()) {
                        await auth.signInWithPhone(
                          name: _nameCtrl.text,
                          phone: _phoneCtrl.text,
                          city: _cityCtrl.text,
                          role: _role,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: auth.isBanned ? Colors.grey : Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                    ),
                    child: auth.loading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(auth.isBanned ? 'Заблокирован' : 'Войти', style: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
