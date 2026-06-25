import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart' as OurAuth;
import '../services/auth_service.dart';
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
    _listenOnline();
  }

  void _listenOnline() {
    FirebaseFirestore.instance.collection('users').doc(widget.order.authorId).snapshots().listen((doc) {
      if (doc.exists && mounted) {
        final user = AppUser.fromMap(doc.data()!);
        setState(() => _isOnline = user.isOnline);
      }
    });
  }

  Future<void> _findChat() async {
    final u = context.read<OurAuth.AuthProvider>().user;
    if (u == null) return;
    final s = await FirebaseFirestore.instance.collection('chats')
        .where('participants', arrayContains: u.phone)
        .get();
    for (var d in s.docs) {
      final participants = List<String>.from(d.data()['participants'] ?? []);
      if (participants.contains(widget.order.authorId) && 
          participants.contains(u.phone)) {
        setState(() => _chatId = d.id);
        return;
      }
    }
  }

  Future<String> _createChat() async {
    final u = context.read<OurAuth.AuthProvider>().user!;
    final s = await FirebaseFirestore.instance.collection('chats')
        .where('participants', arrayContains: u.phone)
        .get();
    for (var d in s.docs) {
      final participants = List<String>.from(d.data()['participants'] ?? []);
      if (participants.contains(widget.order.authorId) && 
          participants.contains(u.phone)) {
        return d.id;
      }
    }
    final ref = FirebaseFirestore.instance.collection('chats').doc();
    await ref.set({
      'participants': [u.phone, widget.order.authorId],
      'orderId': widget.order.id,
      'lastMessage': 'Чат создан',
      'lastMessageTime': DateTime.now().toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
    });
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
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'))); }
    setState(() => _loading = false);
  }

  Future<void> _banUser() async {
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Забанить автора?'),
      content: const Text('Пользователь не сможет войти в течение 24 часов.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Забанить', style: TextStyle(color: Colors.red))),
      ],
    ));
    if (confirm != true) return;
    try {
      await AuthService().banUser(widget.order.authorId, 24);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Пользователь забанен на 24 часа')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  Future<void> _unbanUser() async {
    try {
      await AuthService().unbanUser(widget.order.authorId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Бан снят')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cu = context.read<OurAuth.AuthProvider>().user;
    final own = cu?.phone == widget.order.authorId;
    final isAdmin = cu?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(widget.order.title), actions: [
        if (own) IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => CreateOrderScreen(existingOrder: widget.order)))),
        if (isAdmin && !own) PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'ban') _banUser();
            else if (v == 'unban') _unbanUser();
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'ban', child: Text('Забанить на 24 часа')),
            const PopupMenuItem(value: 'unban', child: Text('Разбанить')),
          ],
        ),
      ]),
      body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Автор: ${widget.order.authorName}', style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: _isOnline ? Colors.green : Colors.grey.shade400)),
          const SizedBox(width: 4),
          Text(_isOnline ? 'онлайн' : 'был(а) недавно', style: TextStyle(fontSize: 12, color: _isOnline ? Colors.green : Colors.grey)),
        ]),
        const SizedBox(height: 8), Text('Город: ${widget.order.city}'), const SizedBox(height: 8),
        if (widget.order.address != null && widget.order.address!.isNotEmpty) Text('Адрес: ${widget.order.address}'),
        const SizedBox(height: 8),
        Text('Бюджет: ${widget.order.budget} ₽', style: const TextStyle(fontWeight: FontWeight.bold)), const Divider(),
        Text(widget.order.description), const SizedBox(height: 16),
        if (!own && cu != null && !isAdmin) Row(children: [
          ElevatedButton.icon(icon: const Icon(Icons.phone), label: Text(widget.order.authorPhone), onPressed: () {}),
          const SizedBox(width: 16),
          ElevatedButton.icon(icon: _loading ? const SizedBox(width:16,height:16,child: CircularProgressIndicator(color:Colors.white)) : const Icon(Icons.chat), label: Text(_chatId!=null?'Открыть чат':'Написать'), style: ElevatedButton.styleFrom(backgroundColor: _chatId!=null?Colors.green:Colors.orange), onPressed: _loading?null:_openChat),
        ]),
        if (own && _chatId!=null) OutlinedButton.icon(icon: const Icon(Icons.chat), label: const Text('Открыть чат с исполнителем'), onPressed: _openChat),
        if (own && _chatId==null) const Text('Это ваше объявление', style: TextStyle(color: Colors.grey)),
      ])),
    );
  }
}
