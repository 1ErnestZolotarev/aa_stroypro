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
        if (u.role == 'customer' && !u.isPro) Container(padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom:16), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)), child: Row(children: [const Icon(Icons.info_outline, color: Colors.orange, size:20), const SizedBox(width:8), Expanded(child: Text(u.role=='customer'?'Лимит: ${u.ordersLimit} заказов':'Можно разместить 1 предложение', style: const TextStyle(fontSize:14)))])),
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
        if (!u.isPro && !_editing) {
          final s = await FirebaseFirestore.instance.collection('orders').where('authorId', isEqualTo: u.uid).get();
          if (u.role == 'customer' && s.docs.length >= u.ordersLimit) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Лимит ${u.ordersLimit} заказов'))); setState(() => _publishing = false); return; }
          if (u.role == 'executor' && s.docs.length >= 1) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('У вас уже есть предложение'))); setState(() => _publishing = false); return; }
        }
        final o = ServiceOrder(id: _editing?widget.existingOrder!.id:DateTime.now().millisecondsSinceEpoch.toString(), authorId: _editing?widget.existingOrder!.authorId:u.uid, authorName: _editing?widget.existingOrder!.authorName:u.name, authorPhone: u.phone, title: _title.text, description: _desc.text, budget: int.tryParse(_budget.text)??0, city: _norm(_city.text), address: _addr.text, type: _type, keywords: SearchService.extractKeywords('${_title.text} ${_desc.text}'), createdAt: _editing?widget.existingOrder!.createdAt:DateTime.now());
        if (_editing) { await FirestoreService().updateOrder(o); } else { await FirestoreService().addOrder(o); }
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editing?'Обновлено!':'Опубликовано!'))); Navigator.pop(context); }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'))); }
      finally { if (mounted) setState(() => _publishing = false); }
    }
  }

  Future<void> _delete() async {
    final c = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Удалить?'), content: const Text('Нельзя отменить.'), actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Удалить',style:TextStyle(color:Colors.red)))]));
    if (c==true && mounted) { await FirestoreService().deleteOrder(widget.existingOrder!.id); Navigator.pop(context); }
  }
}
