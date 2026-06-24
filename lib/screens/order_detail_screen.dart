import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import 'chat_screen.dart';
import 'create_order_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final ServiceOrder order;
  const OrderDetailScreen({required this.order, super.key});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _chatId;
  bool _loading = false;
  bool _isOnline = false;

  @override
  void initState() {
    super.initState();
    _findChat();
    _checkOnline();
  }

  Future<void> _checkOnline() async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(widget.order.authorId).get();
    if (doc.exists) {
      final user = AppUser.fromMap(doc.data()!);
      setState(() => _isOnline = user.isOnline);
    }
  }

  Future<void> _findChat() async {
    final u = context.read<AuthProvider>().user;
    if (u == null) return;
    final s = await FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: u.uid).get();
    for (var d in s.docs) {
      if ((d.data()['orderId'] as String?) == widget.order.id && List<String>.from(d.data()['participants']).contains(widget.order.authorId)) {
        setState(() => _chatId = d.id);
        return;
      }
    }
  }

  Future<String> _createChat() async {
    final u = context.read<AuthProvider>().user!;
    final s = await FirebaseFirestore.instance.collection('chats').where('participants', arrayContains: u.uid).get();
    for (var d in s.docs) {
      if ((d.data()['orderId'] as String?) == widget.order.id && List<String>.from(d.data()['participants']).contains(widget.order.authorId)) return d.id;
    }
    final ref = FirebaseFirestore.instance.collection('chats').doc();
    await ref.set({'participants': [u.uid, widget.order.authorId], 'orderId': widget.order.id, 'lastMessage': '', 'lastMessageTime': DateTime.now().toIso8601String()});
    return ref.id;
  }

  Future<void> _openChat() async {
    setState(() => _loading = true);
    try {
      final id = await _createChat();
      if (mounted && id.isNotEmpty) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chatId: id)));
        _findChat();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final cu = context.read<AuthProvider>().user;
    final own = cu?.uid == widget.order.authorId;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.title),
        actions: [if (own) IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CreateOrderScreen(existingOrder: widget.order))))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Автор с индикатором онлайн
          Row(children: [
            Text('Автор: ${widget.order.authorName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isOnline ? Colors.green : Colors.grey.shade400,
              ),
            ),
            const SizedBox(width: 4),
            Text(_isOnline ? 'онлайн' : 'был(а) недавно', style: TextStyle(fontSize: 12, color: _isOnline ? Colors.green : Colors.grey)),
          ]),
          const SizedBox(height: 8),
          Text('Город: ${widget.order.city}'),
          const SizedBox(height: 8),
          Text('Бюджет: ${widget.order.budget} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Text(widget.order.description),
          const SizedBox(height: 16),
          if (!own && cu != null) Row(children: [
            ElevatedButton.icon(icon: const Icon(Icons.phone), label: Text(widget.order.authorPhone), onPressed: () {}),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              icon: _loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white)) : const Icon(Icons.chat),
              label: Text(_chatId != null ? 'Открыть чат' : 'Написать'),
              style: ElevatedButton.styleFrom(backgroundColor: _chatId != null ? Colors.green : Colors.orange),
              onPressed: _loading ? null : _openChat,
            ),
          ]),
          if (own && _chatId != null) OutlinedButton.icon(icon: const Icon(Icons.chat), label: const Text('Открыть чат'), onPressed: _openChat),
          // Статус заказа
          if (own) Row(children: [
            const Text("Статус: "),
            DropdownButton<String>(
              value: widget.order.status,
              items: const [
                DropdownMenuItem(value: "active", child: Text("Активен")),
                DropdownMenuItem(value: "in_work", child: Text("В работе")),
                DropdownMenuItem(value: "completed", child: Text("Завершён")),
              ],
              onChanged: (v) async {
                if (v != null) {
                  await FirebaseFirestore.instance.collection("orders").doc(widget.order.id).update({"status": v});
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          ]),
          const SizedBox(height: 16),
          if (own && _chatId == null) const Text('Это ваше объявление', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}
