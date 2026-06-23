import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _findExistingChat();
  }

  Future<void> _findExistingChat() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      final orderId = doc.data()['orderId'] as String?;
      if (participants.contains(widget.order.authorId) && orderId == widget.order.id) {
        setState(() => _chatId = doc.id);
        return;
      }
    }
  }

  Future<String> _createOrGetChat() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return '';

    // Ищем существующий чат
    final snapshot = await FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .get();

    for (var doc in snapshot.docs) {
      final participants = List<String>.from(doc.data()['participants'] ?? []);
      final orderId = doc.data()['orderId'] as String?;
      if (participants.contains(widget.order.authorId) && orderId == widget.order.id) {
        return doc.id;
      }
    }

    // Создаём новый чат
    final chatRef = FirebaseFirestore.instance.collection('chats').doc();
    await chatRef.set({
      'participants': [user.uid, widget.order.authorId],
      'orderId': widget.order.id,
      'lastMessage': '',
      'lastMessageTime': DateTime.now().toIso8601String(),
    });
    return chatRef.id;
  }

  Future<void> _openChat() async {
    setState(() => _isLoading = true);
    try {
      final chatId = await _createOrGetChat();
      if (mounted && chatId.isNotEmpty) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(chatId: chatId),
          ),
        ).then((_) {
          // Обновляем chatId после возврата из чата
          _findExistingChat();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    final isOwn = currentUser?.uid == widget.order.authorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.title),
        actions: [
          if (isOwn)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Редактировать',
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateOrderScreen(existingOrder: widget.order),
                  ),
                );
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Автор: ${widget.order.authorName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Город: ${widget.order.city}'),
            const SizedBox(height: 8),
            Text('Бюджет: ${widget.order.budget} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text(widget.order.description),
            const SizedBox(height: 16),
            // Кнопка телефона и чата
            if (!isOwn && currentUser != null) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: Text(widget.order.authorPhone),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: _isLoading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white))
                        : const Icon(Icons.chat),
                    label: Text(_chatId != null ? 'Открыть чат' : 'Написать'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _chatId != null ? Colors.green : Colors.orange,
                    ),
                    onPressed: _isLoading ? null : _openChat,
                  ),
                ],
              ),
            ],
            // Если это своё объявление — тоже можно открыть чат
            if (isOwn && _chatId != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.chat),
                label: const Text('Открыть чат с исполнителем'),
                onPressed: _openChat,
              ),
            ],
            if (isOwn && _chatId == null)
              const Text('Это ваше объявление', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
