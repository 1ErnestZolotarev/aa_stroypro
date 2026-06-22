import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/search_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final ServiceOrder? existingOrder;

  const CreateOrderScreen({super.key, this.existingOrder});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _budgetCtrl;
  late TextEditingController _cityCtrl;
  late String _type;
  bool _isPublishing = false;

  bool get _isEditing => widget.existingOrder != null;

  @override
  void initState() {
    super.initState();
    final order = widget.existingOrder;
    _titleCtrl = TextEditingController(text: order?.title ?? '');
    _descCtrl = TextEditingController(text: order?.description ?? '');
    _budgetCtrl = TextEditingController(text: order?.budget.toString() ?? '');
    _cityCtrl = TextEditingController(text: order?.city ?? '');
    _type = order?.type ?? 'request';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _budgetCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  String _normalizeCity(String input) {
    return input.trim().split(' ').map((w) {
      if (w.isEmpty) return '';
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }

  /// Проверяет, не превышен ли лимит объявлений
  Future<bool> _checkLimit() async {
    final user = context.read<AuthProvider>().user!;
    
    // PRO пользователи без лимита
    if (user.isPro && user.ordersLimit == 0) return true;
    
    // Считаем текущие объявления пользователя
    final snapshot = await FirebaseFirestore.instance
        .collection('orders')
        .where('authorId', isEqualTo: user.uid)
        .get();
    
    return snapshot.docs.length < user.ordersLimit;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Редактировать объявление' : 'Новое объявление'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Удалить',
              onPressed: _deleteOrder,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Информация о лимите
              if (!user.isPro)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Бесплатный лимит: ${user.ordersLimit} объявлений',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Название работы'),
                validator: (v) => v!.isEmpty ? 'Обязательно' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Бюджет (₽)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(labelText: 'Город'),
                validator: (v) => v!.isEmpty ? 'Укажите город' : null,
              ),
              const SizedBox(height: 16),
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
                      child: Text(_isEditing ? 'Сохранить' : 'Опубликовать'),
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
        // Проверяем лимит (только для новых объявлений)
        if (!_isEditing) {
          final canCreate = await _checkLimit();
          if (!canCreate) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Достигнут лимит бесплатных объявлений'),
                  action: SnackBarAction(
                    label: 'PRO',
                    onPressed: () {
                      // В будущем здесь будет экран подписки
                    },
                  ),
                ),
              );
            }
            return;
          }
        }

        final user = context.read<AuthProvider>().user!;
        final orderId = _isEditing ? widget.existingOrder!.id : DateTime.now().millisecondsSinceEpoch.toString();
        final fullText = '${_titleCtrl.text} ${_descCtrl.text}';
        final keywords = SearchService.extractKeywords(fullText);

        final order = ServiceOrder(
          id: orderId,
          authorId: _isEditing ? widget.existingOrder!.authorId : user.uid,
          authorName: _isEditing ? widget.existingOrder!.authorName : user.name,
          authorPhone: user.phone,
          title: _titleCtrl.text,
          description: _descCtrl.text,
          budget: int.tryParse(_budgetCtrl.text) ?? 0,
          city: _normalizeCity(_cityCtrl.text),
          type: _type,
          keywords: keywords,
          createdAt: _isEditing ? widget.existingOrder!.createdAt : DateTime.now(),
        );

        final firestoreService = FirestoreService();
        if (_isEditing) {
          await firestoreService.updateOrder(order);
        } else {
          await firestoreService.addOrder(order);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_isEditing ? 'Объявление обновлено!' : 'Объявление опубликовано!')),
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

  Future<void> _deleteOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить объявление?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await FirestoreService().deleteOrder(widget.existingOrder!.id);
      Navigator.pop(context);
    }
  }
}
