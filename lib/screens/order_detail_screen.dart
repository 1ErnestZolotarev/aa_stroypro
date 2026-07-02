import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../services/firestore_service.dart';
import 'create_order_screen.dart';
import 'chat_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final ServiceOrder order;
  const OrderDetailScreen({required this.order, super.key});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String? _chatId;
  bool _loading = false;
  bool _isAuthorOnline = false;

  @override
  void initState() {
    super.initState();
    _checkChat();
    _loadAuthorStatus();
  }

  Future<void> _checkChat() async {
    final user = context.read<OurAuth.AuthProvider>().user;
    if (user == null) return;
    final otherId = widget.order.authorPhone;
    if (otherId == user.phone) return;
    final firestore = FirestoreService();
    final chatId = await firestore.createOrGetChat(user.phone, otherId, orderId: widget.order.id);
    setState(() => _chatId = chatId);
  }

  Future<void> _loadAuthorStatus() async {
    final docId = widget.order.authorPhone.replaceAll(RegExp(r'\D'), '');
    final doc = await FirebaseFirestore.instance.collection('users').doc(docId).get();
    if (doc.exists) {
      final author = AppUser.fromMap(doc.data()!);
      setState(() {
        _isAuthorOnline = author.isOnline;
      });
    }
  }

  Future<String> _createChat(String otherUserId) async {
    final user = context.read<OurAuth.AuthProvider>().user;
    if (user == null) throw Exception('User not authenticated');
    final firestore = FirestoreService();
    final chatId = await firestore.createOrGetChat(user.phone, otherUserId, orderId: widget.order.id);
    return chatId;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<OurAuth.AuthProvider>().user;
    final isAuthor = user?.phone == widget.order.authorPhone;
    final isAdmin = user?.isAdmin ?? false;
    final canEdit = isAuthor || isAdmin;
    final hasChat = _chatId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.order.title),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateOrderScreen(existingOrder: widget.order),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.order.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Город', widget.order.city),
            _buildInfoRow('Автор', widget.order.authorName),
            _buildInfoRow('Телефон', widget.order.authorPhone),
            _buildInfoRow('Тип', widget.order.type),
            _buildInfoRow('Бюджет', '${widget.order.budget} ₽'),
            _buildInfoRow('Дата', widget.order.createdAt.toLocal().toString().substring(0, 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Статус автора:'),
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 6,
                  backgroundColor: _isAuthorOnline ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  _isAuthorOnline ? 'онлайн' : 'не в сети',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const Divider(height: 32),
            if (user != null && user.phone != widget.order.authorPhone)
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (hasChat)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(chatId: _chatId!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Перейти в чат'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      final chatId = await _createChat(widget.order.authorPhone);
                      setState(() => _chatId = chatId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chatId),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ошибка: $e')),
                      );
                    } finally {
                      setState(() => _loading = false);
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('Написать автору'),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
