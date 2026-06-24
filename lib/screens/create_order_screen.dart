import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/search_service.dart';

class CreateOrderScreen extends StatefulWidget { final ServiceOrder? existingOrder; const CreateOrderScreen({super.key, this.existingOrder}); @override State<CreateOrderScreen> createState() => _CreateOrderScreenState(); }
class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _f = GlobalKey<FormState>();
  late TextEditingController _title, _desc, _budget, _city, _addr;
  late String _type;
  bool _publishing = false;
  bool get _editing => widget.existingOrder != null;

  @override
  void initState() { super.initState(); final o = widget.existingOrder; _title = TextEditingController(text: o?.title??''); _desc = TextEditingController(text: o?.description??''); _budget = TextEditingController(text: o?.budget.toString()??''); _city = TextEditingController(text: o?.city??''); _addr = TextEditingController(text: o?.address??''); _type = o?.type??'request'; }
  @override
  void dispose() { _title.dispose(); _desc.dispose(); _budget.dispose(); _city.dispose(); _addr.dispose(); super.dispose(); }
  String _norm(String s) => s.trim().split(' ').map((w) => w.isEmpty?'':'${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  @override
  Widget build(BuildContext context) {
    final u = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: Text(_editing?'Редактировать':'Новое объявление'), actions: [if(_editing) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _delete)]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _f, child: Column(children: [
        _tf(_title, 'Название работы'), const SizedBox(height:8),
        _tf(_desc, 'Описание', lines: 3), const SizedBox(height:8),
        _tf(_budget, 'Бюджет (₽)', num: true), const SizedBox(height:8),
        _tf(_city, 'Город'), const SizedBox(height:8),
        _tf(_addr, 'Адрес объекта'), const SizedBox(height:16),
        TextFormField(initialValue: u.phone, decoration: const InputDecoration(labelText: 'Контактный телефон', prefixIcon: Icon(Icons.phone)), enabled: false),
        const SizedBox(height:16),
        SegmentedButton<String>(segments: const [ButtonSegment(value:'request',label:Text('Ищу исполнителя')),ButtonSegment(value:'offer',label:Text('Предлагаю услуги'))], selected: {_type}, onSelectionChanged: _publishing?null:(s) => setState(() => _type = s.first)),
        const SizedBox(height:24),
        _publishing ? const CircularProgressIndicator() : ElevatedButton(onPressed: _publish, child: Text(_editing?'Сохранить':'Опубликовать')),
      ]))),
    );
  }

  Widget _tf(TextEditingController c, String label, {int lines=1, bool num=false}) => TextFormField(controller: c, maxLines: lines, keyboardType: num?TextInputType.number:null, decoration: InputDecoration(labelText: label));

  Future<void> _publish() async {
    if (_f.currentState!.validate() && !_publishing) {
      setState(() => _publishing = true);
      try {
        final u = context.read<AuthProvider>().user!;
