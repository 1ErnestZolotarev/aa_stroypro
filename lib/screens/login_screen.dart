import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _f = GlobalKey<FormState>();
  final _name = TextEditingController(), _phone = TextEditingController(), _city = TextEditingController();
  String _role = 'customer';

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
        if (a.isBanned) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 16), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.block, color: Colors.red), const SizedBox(width: 8), Expanded(child: Text('Аккаунт заблокирован.\n${a.error??""}', style: const TextStyle(color: Colors.red)))])),
        TextFormField(
          controller: _name,
          decoration: InputDecoration(labelText: 'Ваше имя', prefixIcon: const Icon(Icons.person, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          inputFormatters: [CapitalizeFirstLetterFormatter()],
          validator: (v) => v!.isEmpty ? 'Введите имя' : null,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _phone,
          decoration: InputDecoration(labelText: 'Телефон', prefixIcon: const Icon(Icons.phone, color: Colors.grey), hintText: '+7 (___) ___-__-__', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneInputFormatter()],
          validator: (v) {
            if (v == null || v.isEmpty) return 'Введите телефон';
            final digits = v.replaceAll(RegExp(r'\D'), '');
            if (digits.length != 11) return 'Номер должен содержать 11 цифр';
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _city,
          decoration: InputDecoration(labelText: 'Город', prefixIcon: const Icon(Icons.location_city, color: Colors.grey), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
          inputFormatters: [CapitalizeFirstLetterFormatter()],
          validator: (v) => v!.isEmpty ? 'Введите город' : null,
        ),
        const SizedBox(height: 24),
        Row(children: [Expanded(child: _roleBtn('Я заказчик','customer')), const SizedBox(width: 24), Expanded(child: _roleBtn('Я исполнитель','executor'))]),
        const SizedBox(height: 24),
        if (a.error != null && !a.isBanned) Padding(padding: const EdgeInsets.only(bottom: 16), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: Text(a.error!, style: TextStyle(color: Colors.red.shade700), textAlign: TextAlign.center))),
        SizedBox(width: double.infinity, height: 50, child: ElevatedButton(
          onPressed: a.loading||a.isBanned ? null : () { if (_f.currentState!.validate()) a.signInWithPhone(name: _name.text, phone: _phone.text.replaceAll(RegExp(r'\D'), ''), city: _city.text, role: _role); },
          style: ElevatedButton.styleFrom(backgroundColor: a.isBanned ? Colors.grey : Colors.orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: a.loading ? const SizedBox(width:24,height:24,child: CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : Text(a.isBanned?'Заблокирован':'Войти', style: const TextStyle(fontSize:16)),
        )),
        const SizedBox(height: 32),
        GestureDetector(
          onTap: () => _openUrl('https://telegra.ph/Politika-konfidencialnosti-06-23'),
          child: Text('Политика конфиденциальности', style: TextStyle(fontSize: 12, color: Colors.grey.shade500, decoration: TextDecoration.underline)),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openUrl('https://telegra.ph/Polzovatelskoe-soglashenie-06-23'),
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

  Future<void> _openUrl(String url) async { final u = Uri.parse(url); if (await canLaunchUrl(u)) await launchUrl(u, mode: LaunchMode.externalApplication); }
}

class CapitalizeFirstLetterFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final words = newValue.text.split(' ').where((w) => w.isNotEmpty).map((w) {
      if (w.length == 1) return w.toUpperCase();
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
    return TextEditingValue(text: words, selection: TextSelection.collapsed(offset: words.length));
  }
}

class PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return const TextEditingValue(text: '');
    String formatted = '+7 ';
    if (digits.length > 1) formatted += '(${digits.substring(1, digits.length > 4 ? 4 : digits.length)}';
    if (digits.length > 4) formatted += ') ${digits.substring(4, digits.length > 7 ? 7 : digits.length)}';
    if (digits.length > 7) formatted += '-${digits.substring(7, digits.length > 9 ? 9 : digits.length)}';
    if (digits.length > 9) formatted += '-${digits.substring(9, digits.length > 11 ? 11 : digits.length)}';
    return TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
  }
}
