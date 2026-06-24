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
