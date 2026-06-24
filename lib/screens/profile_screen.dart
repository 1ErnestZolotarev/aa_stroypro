import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../models/order_model.dart';
import 'order_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  String _role = 'customer';
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _role = user?.role ?? 'customer';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      try {
        await context.read<AuthProvider>().updateProfile(name: _nameCtrl.text, phone: _phoneCtrl.text, city: _cityCtrl.text, role: _role);
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Профиль обновлён!'))); setState(() => _isEditing = false); }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold(body: Center(child: Text('Пользователь не найден')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          if (!_isEditing) IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true))
          else IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isEditing = false)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(radius: 50, backgroundColor: Colors.orange.shade100, child: Icon(Icons.person, size: 50, color: Colors.orange.shade700)),
              const SizedBox(height: 24),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Имя', prefixIcon: Icon(Icons.person)), enabled: _isEditing, validator: (v) => v!.isEmpty ? 'Введите имя' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Телефон', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone, enabled: _isEditing, validator: (v) => v!.isEmpty ? 'Введите телефон' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'Город', prefixIcon: Icon(Icons.location_city)), enabled: _isEditing, validator: (v) => v!.isEmpty ? 'Введите город' : null),
              const SizedBox(height: 16),
              SegmentedButton<String>(segments: const [ButtonSegment(value: 'customer', label: Text('Заказчик')), ButtonSegment(value: 'executor', label: Text('Исполнитель'))], selected: {_role}, onSelectionChanged: _isEditing ? (s) => setState(() => _role = s.first) : null),
              const SizedBox(height: 32),
              if (_isEditing) _isSaving ? const CircularProgressIndicator() : ElevatedButton.icon(icon: const Icon(Icons.save), label: const Text('Сохранить'), onPressed: _saveProfile),
              const SizedBox(height: 24),
              // Мои заказы
              const Divider(),
              // Избранное
              const Divider(),
              const Padding(padding: EdgeInsets.all(8), child: Text("Избранное", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection("orders").where(FieldPath.documentId, whereIn: user.favorites.isEmpty ? [""] : user.favorites).get(),
                builder: (_, s) {
                  if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!s.hasData || s.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(16), child: Text("Нет избранных объявлений", style: TextStyle(color: Colors.grey)));
                  return ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: s.data!.docs.length, itemBuilder: (_, i) {
                    final o = ServiceOrder.fromMap(s.data!.docs[i].id, s.data!.docs[i].data() as Map<String, dynamic>);
                    return Card(child: ListTile(title: Text(o.title, maxLines: 1), subtitle: Text("${o.city} • ${o.budget} ₽"), trailing: Chip(label: Text(o.type == "offer" ? "Исполнитель" : "Заказчик")), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)))));
                  });
                },
              ),
              const Divider(),
              const Padding(padding: EdgeInsets.all(8), child: Text('Мои объявления', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('orders').where('authorId', isEqualTo: user.uid).orderBy('createdAt', descending: true).get(),
                builder: (ctx, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Text('Ошибка загрузки: ${snap.error}');
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('У вас пока нет объявлений', style: TextStyle(color: Colors.grey)),
                    );
                  }
                  final orders = snap.data!.docs;
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (ctx, i) {
                      final order = ServiceOrder.fromMap(orders[i].id, orders[i].data() as Map<String, dynamic>);
                      return Card(
                        child: ListTile(
                          title: Text(order.title, maxLines: 1),
                          subtitle: Text('${order.city} • ${order.budget} ₽'),
                          trailing: Chip(label: Text(order.type == 'offer' ? 'Исполнитель' : 'Заказчик')),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              const Divider(),
              ListTile(leading: const Icon(Icons.mail_outline, color: Colors.orange), title: const Text('Написать разработчику'), subtitle: const Text('ernest779977@gmail.com'), trailing: const Icon(Icons.chevron_right), onTap: () { Clipboard.setData(const ClipboardData(text: 'ernest779977@gmail.com')); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email скопирован!'))); }),
              const Divider(),
              ListTile(leading: const Icon(Icons.info_outline), title: const Text('Версия'), subtitle: const Text('1.0.0')),
              const SizedBox(height: 16),
              OutlinedButton.icon(icon: const Icon(Icons.logout, color: Colors.red), label: const Text('Выйти', style: TextStyle(color: Colors.red)), onPressed: () async => await auth.logout()),
            ],
          ),
        ),
      ),
    );
  }
}
