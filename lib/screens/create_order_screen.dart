import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../services/search_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final ServiceOrder? existingOrder; // null = создание, не null = редактирование

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
  final List<File> _photos = [];
  final ImagePicker _picker = ImagePicker();

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

  Future<void> _pickPhoto() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Максимум 5 фото')),
      );
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photos.add(File(image.path));
      });
    }
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
              Row(
                children: [
                  const Text('Фото (до 5):', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Добавить'),
                    onPressed: _pickPhoto,
                  ),
                ],
              ),
              if (_photos.isNotEmpty) ...[
                const SizedBox(height: 8),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _photos.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Image.file(_photos[i], width: 100, height: 100, fit: BoxFit.cover),
                          Positioned(
                            top: 0, right: 0,
                            child: GestureDetector(
                              onTap: () => setState(() => _photos.removeAt(i)),
                              child: const Icon(Icons.cancel, color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
          photoUrls: _isEditing ? widget.existingOrder!.photoUrls : [],
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
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.existingOrder!.id)
          .delete();
      Navigator.pop(context);
    }
  }
}
