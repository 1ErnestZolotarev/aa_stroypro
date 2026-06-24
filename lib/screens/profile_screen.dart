import "chat_screen.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';

class ProfileScreen extends StatefulWidget { const ProfileScreen({super.key}); @override State<ProfileScreen> createState() => _ProfileScreenState(); }
class _ProfileScreenState extends State<ProfileScreen> {
  final _f = GlobalKey<FormState>();
  late TextEditingController _name, _phone, _city;
  String _role = 'customer';
  bool _editing = false, _saving = false;

  @override
  void initState() { super.initState(); final u = context.read<AuthProvider>().user; _name = TextEditingController(text: u?.name??''); _phone = TextEditingController(text: u?.phone??''); _city = TextEditingController(text: u?.city??''); _role = u?.role??'customer'; }
  @override
  void dispose() { _name.dispose(); _phone.dispose(); _city.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final a = context.watch<AuthProvider>();
    final u = a.user;
    if (u==null) return const Scaffold(body: Center(child: Text('Пользователь не найден')));
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль'), actions: [if(!_editing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _editing = true)) else IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _editing = false))]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Form(key: _f, child: Column(children: [
        CircleAvatar(radius:50, backgroundColor: Colors.orange.shade100, child: Icon(Icons.person, size:50, color: Colors.orange.shade700)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.star, color: Colors.amber, size: 20),
          const SizedBox(width: 4),
          Text(u.rating.toStringAsFixed(1), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          Text('(${u.totalRatings})', style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
        ]),
        const SizedBox(height: 16),
        TextFormField(controller: _name, decoration: const InputDecoration(labelText:'Имя',prefixIcon:Icon(Icons.person)), enabled: _editing, validator: (v)=>v!.isEmpty?'Введите имя':null), const SizedBox(height:16),
        TextFormField(controller: _phone, decoration: const InputDecoration(labelText:'Телефон',prefixIcon:Icon(Icons.phone)), keyboardType: TextInputType.phone, enabled: _editing, validator: (v)=>v!.isEmpty?'Введите телефон':null), const SizedBox(height:16),
        TextFormField(controller: _city, decoration: const InputDecoration(labelText:'Город',prefixIcon:Icon(Icons.location_city)), enabled: _editing, validator: (v)=>v!.isEmpty?'Введите город':null), const SizedBox(height:16),
        SegmentedButton<String>(segments: const [ButtonSegment(value:'customer',label:Text('Заказчик')),ButtonSegment(value:'executor',label:Text('Исполнитель'))], selected: {_role}, onSelectionChanged: _editing?(s)=>setState(()=>_role=s.first):null), const SizedBox(height:32),
        if (_editing) _saving ? const CircularProgressIndicator() : ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Сохранить'), onPressed: () async { if(_f.currentState!.validate()&&!_saving){setState(()=>_saving=true); try{await a.updateProfile(name:_name.text,phone:_phone.text,city:_city.text,role:_role); if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Обновлено!')));setState(()=>_editing=false);}}catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Ошибка:$e')));}finally{if(mounted)setState(()=>_saving=false);}}}), const SizedBox(height:24),
          const Divider(),
          const Padding(padding: EdgeInsets.all(8), child: Text("Мои чаты", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("chats").where("participants", arrayContains: u.uid).orderBy("lastMessageTime", descending: true).snapshots(),
            builder: (_, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              if (s.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("Нет чатов", style: TextStyle(color: Colors.grey)));
              return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: s.data!.docs.length, itemBuilder: (_, i) {
                final d = s.data!.docs[i].data() as Map<String, dynamic>;
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: const Icon(Icons.chat, color: Colors.orange)),
                  title: Text(d["lastMessage"] as String? ?? "Новый чат"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: s.data!.docs[i].id))),
                );
              });
            },
          ),
          const Divider(),
        const Divider(), const Padding(padding: EdgeInsets.all(8), child: Text('Мои объявления', style: TextStyle(fontSize:18, fontWeight: FontWeight.bold))),
        FutureBuilder<QuerySnapshot>(future: FirebaseFirestore.instance.collection('orders').where('authorId', isEqualTo: u.uid).get(), builder: (_,s) {
          if (s.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (s.hasError) return Padding(padding: const EdgeInsets.all(16), child: Text('Ошибка: ${s.error}', style: const TextStyle(color: Colors.red)));
          if (!s.hasData||s.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text('У вас пока нет объявлений', style: TextStyle(color: Colors.grey)));
          return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: s.data!.docs.length, itemBuilder: (_,i) {
            final o = ServiceOrder.fromMap(s.data!.docs[i].id, s.data!.docs[i].data() as Map<String, dynamic>);
            return Card(child: ListTile(title: Text(o.title, maxLines:1), subtitle: Text('${o.city} • ${o.budget} ₽'), trailing: Chip(label: Text(o.type=='offer'?'Исполнитель':'Заказчик')), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)))));
          });
        }), const SizedBox(height:24),
        const Divider(),
        ListTile(leading: const Icon(Icons.mail_outline, color: Colors.orange), title: const Text('Написать разработчику'), subtitle: const Text('ernest779977@gmail.com'), trailing: const Icon(Icons.chevron_right), onTap: () { Clipboard.setData(const ClipboardData(text:'ernest779977@gmail.com')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email скопирован!'))); }),
        const Divider(),
        ListTile(leading: const Icon(Icons.info_outline), title: const Text('Версия'), subtitle: const Text('1.0.0')),
        const SizedBox(height:16),
        OutlinedButton.icon(icon: const Icon(Icons.logout, color: Colors.red), label: const Text('Выйти', style: TextStyle(color: Colors.red)), onPressed: () async => await a.logout()),
      ]))),
    );
  }
}
