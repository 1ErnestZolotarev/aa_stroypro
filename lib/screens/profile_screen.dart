import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import 'order_detail_screen.dart';

class ProfileScreen extends StatefulWidget { const ProfileScreen({super.key}); @override State<ProfileScreen> createState() => _ProfileScreenState(); }
class _ProfileScreenState extends State<ProfileScreen> {
  final _f = GlobalKey<FormState>();
  late TextEditingController _name, _city;
  String _role = 'customer';
  bool _editing = false, _saving = false;
  final _emailCtrl = TextEditingController(), _passCtrl = TextEditingController();

  @override
  void initState() { super.initState(); final u = context.read<AuthProvider>().user; _name = TextEditingController(text: u?.name??''); _city = TextEditingController(text: u?.city??''); _role = u?.role??'customer'; }
  @override
  void dispose() { _name.dispose(); _city.dispose(); _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _linkEmail() async {
    final phone = context.read<AuthProvider>().currentPhone;
    if (phone == null) return;
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Введите корректный email')));
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пароль должен быть не менее 6 символов')));
      return;
    }
    try {
      await AuthService().linkEmail(phone, email, password);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Письмо для подтверждения отправлено на почту')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    final u = a.user;
    if (u==null) return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль'), actions: [if(!_editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true)) else IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _editing = false))]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _f, child: Column(children: [
        CircleAvatar(radius:50, backgroundColor: Colors.orange.shade100, child: Icon(Icons.person, size:50, color: Colors.orange.shade700)), const SizedBox(height:16),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText:'Имя',prefixIcon:Icon(Icons.person)), enabled: _editing, validator: (v)=>v!.isEmpty?'Введите имя':null), const SizedBox(height:16),
        TextFormField(controller: _city, decoration: const InputDecoration(labelText:'Город',prefixIcon:Icon(Icons.location_city)), enabled: _editing, validator: (v)=>v!.isEmpty?'Введите город':null), const SizedBox(height:16),
        SegmentedButton<String>(segments: const [ButtonSegment(value:'customer',label:Text('Заказчик')),ButtonSegment(value:'executor',label:Text('Исполнитель'))], selected: {_role}, onSelectionChanged: _editing?(s)=>setState(()=>_role=s.first):null), const SizedBox(height:16),
        ListTile(
          leading: const Icon(Icons.email, color: Colors.orange),
          title: const Text('Безопасность'),
          subtitle: const Text('Привяжите email для защиты аккаунта'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
            title: const Text('Привязать email'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), keyboardType: TextInputType.emailAddress),
              TextField(controller: _passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль (мин. 6 символов)')),
            ]),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
              ElevatedButton(onPressed: () { _linkEmail(); Navigator.pop(ctx); }, child: const Text('Привязать')),
            ],
          )),
        ),
        const Divider(),
        if (_editing) ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Сохранить'), onPressed: () async { if(_f.currentState!.validate()){ await a.updateProfile(name:_name.text, city:_city.text, role:_role); setState(()=>_editing=false); } }),
        const Divider(), const Padding(padding: EdgeInsets.all(8), child: Text('Мои объявления', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))),
        FutureBuilder<QuerySnapshot>(future: FirebaseFirestore.instance.collection('orders').where('authorId', isEqualTo: u.phone).get(), builder: (_,s) {
          if (s.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text('Ошибка: ${s.error}', style: const TextStyle(color: Colors.red)));
          if (!s.hasData||s.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('У вас пока нет объявлений', style: TextStyle(color: Colors.grey)));
          return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: s.data!.docs.length, itemBuilder: (_,i) {
            final o = ServiceOrder.fromMap(s.data!.docs[i].id, s.data!.docs[i].data() as Map<String, dynamic>);
            return Card(child: ListTile(title: Text(o.title, maxLines:1), subtitle: Text('${o.city} • ${o.budget} ₽'), trailing: Chip(label: Text(o.type=='offer'?'Исполнитель':'Заказчик')), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)))));
          });
        }),
        const Divider(),
        OutlinedButton.icon(icon: const Icon(Icons.logout, color: Colors.red), label: const Text('Выйти'), onPressed: () => a.logout()),
      ]))),
    );
  }
}
