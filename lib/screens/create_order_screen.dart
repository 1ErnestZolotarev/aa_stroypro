import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/search_service.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String _type = 'request';
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Новое объявление')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Название работы'),
                validator: (v) => v!.isEmpty ? 'Обязательно' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Бюджет (₽)'),
              ),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'Город'),
                validator: (v) => v!.isEmpty ? 'Укажите город' : null,
              ),
              const SizedBox(height: 16),
              // Поле для контакта
              TextFormField(
                initialValue: user.phone,
                decoration: const InputDecoration(
                  labelText: 'Контактный телефон',
                  prefixIcon: Icon(Icons.phone),
                ),
                enabled: false,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'request', label: Text('Ищу исполнителя')),
                  ButtonSegment(value: 'offer', label: Text('Предлагаю услуги')),
                ],
                selected: {_type},
                onSelectionChanged: _isPublishing
                    ? null
                    : (s) => setState(() => _type = s.first),
              ),
              const SizedBox(height: 24),
              _isPublishing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _publishOrder,
                      child: const Text('Опубликовать'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _publishOrder() async {
    if (_formKey.currentState!.validate() && !_isPublishing) {
      setState(() => _isPublishing = true);

      try {
        final user = context.read<AuthProvider>().user!;
        final fullText = '${_titleCtrl.text} ${_descCtrl.text}';
        final keywords = SearchService.extractKeywords(fullText);
        final order = ServiceOrder(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          authorId: user.uid,
          authorName: user.name,
          authorPhone: user.phone,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          budget: int.tryParse(_budgetCtrl.text) ?? 0,
          city: _cityCtrl.text,
          type: _type,
          keywords: keywords,
          createdAt: DateTime.now(),
        );
        await FirestoreService().addOrder(order);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Объявление опубликовано!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isPublishing = false);
        }
      }
    }
  }
}
