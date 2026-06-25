import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../services/firestore_service.dart';
import '../services/search_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final ServiceOrder? existingOrder;
  const CreateOrderScreen({super.key, this.existingOrder});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _f = GlobalKey<FormState>();
  late TextEditingController _title, _desc, _budget, _city, _addr, _nameCtrl, _phoneCtrl;
  late String _type;
  bool _publishing = false;
  bool get _editing => widget.existingOrder != null;
  bool get _isAuthorized => context.read<OurAuth.AuthProvider>().user != null;

  @override
  void initState() {
    super.initState();
    final o = widget.existingOrder;
    final u = context.read<OurAuth.AuthProvider>().user;
    _title = TextEditingController(text: o?.title ?? '');
    _desc = TextEditingController(text: o?.description ?? '');
    _budget = TextEditingController(text: o?.budget.toString() ?? '');
    _city = TextEditingController(text: o?.city ?? '');
    _addr = TextEditingController(text: o?.address ?? '');
    _nameCtrl = TextEditingController(text: o?.authorName ?? u?.name ?? '');
    _phoneCtrl = TextEditingController(text: o?.authorPhone ?? u?.phone ?? '');
    _type = o?.type ?? 'request';
  }

  @override
  void dispose() {
    _title.dispose(); _desc.dispose(); _budget.dispose(); _city.dispose(); _addr.dispose();
    _nameCtrl.dispose(); _phoneCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim().split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' ');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Редактировать' : 'Новое объявление'), actions: [if (_editing) IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _delete)]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Form(key: _f, child: Column(children: [
        if (!_isAuthorized) ...[
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Ваше имя'), validator: (v) => v!.isEmpty ? 'Введите имя' : null),
          const SizedBox(height: 8),
          TextFormField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(labelText: 'Телефон'),
            keyboardType: TextInputType.phone,
            inputFormatters: [PhoneInputFormatter()],
            validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
          ),
          const SizedBox(height: 16),
        ],
        TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Название работы'), validator: (v) => v!.isEmpty ? 'Обязательно' : null),
        const SizedBox(height: 8),
        TextFormField(controller: _desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Описание')),
        const SizedBox(height: 8),
        TextFormField(controller: _budget, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Бюджет (₽)')),
        const SizedBox(height: 8),
        TextFormField(controller: _city, decoration: const InputDecoration(labelText: 'Город'), validator: (v) => v!.isEmpty ? 'Укажите город' : null),
        const SizedBox(height: 8),
        TextFormField(controller: _addr, decoration: const InputDecoration(labelText: 'Адрес объекта')),
        const SizedBox(height: 16),
        SegmentedButton<String>(segments: const [ButtonSegment(value:'request',label:Text('Ищу исполнителя')),ButtonSegment(value:'offer',label:Text('Предлагаю услуги'))], selected: {_type}, onSelectionChanged: _publishing ? null : (s) => setState(() => _type = s.first)),
        const SizedBox(height: 24),
        _publishing ? const CircularProgressIndicator() : ElevatedButton(onPressed: _publish, child: Text(_editing ? 'Сохранить' : 'Опубликовать')),
      ]))),
    );
  }

  Future<void> _publish() async {
    if (_f.currentState!.validate() && !_publishing) {
      setState(() => _publishing = true);
      try {
        final u = context.read<OurAuth.AuthProvider>().user;
        final authorName = _isAuthorized ? (u?.name ?? _nameCtrl.text) : _nameCtrl.text;
        final authorPhone = _isAuthorized ? (u?.phone ?? _phoneCtrl.text) : _phoneCtrl.text;
        final o = ServiceOrder(
          id: _editing ? widget.existingOrder!.id : DateTime.now().millisecondsSinceEpoch.toString(),
          authorId: _isAuthorized ? (u?.phone ?? authorPhone) : authorPhone,
          authorName: authorName,
          authorPhone: authorPhone,
          title: _title.text,
          description: _desc.text,
          budget: int.tryParse(_budget.text) ?? 0,
          city: _norm(_city.text),
          address: _addr.text,
          type: _type,
          keywords: SearchService.extractKeywords('${_title.text} ${_desc.text}'),
          createdAt: _editing ? widget.existingOrder!.createdAt : DateTime.now(),
        );
        if (_editing) { await FirestoreService().updateOrder(o); } else { await FirestoreService().addOrder(o); }
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editing ? 'Обновлено!' : 'Опубликовано!'))); Navigator.pop(context); }
      } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'))); }
      finally { if (mounted) setState(() => _publishing = false); }
    }
  }

  Future<void> _delete() async {
    final c = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(title: const Text('Удалить?'), content: const Text('Нельзя отменить.'), actions: [TextButton(onPressed:()=>Navigator.pop(ctx,false),child:const Text('Отмена')),TextButton(onPressed:()=>Navigator.pop(ctx,true),child:const Text('Удалить',style:TextStyle(color:Colors.red)))]));
    if (c == true && mounted) { await FirestoreService().deleteOrder(widget.existingOrder!.id); Navigator.pop(context); }
  }
}

// Форматтер телефона
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
