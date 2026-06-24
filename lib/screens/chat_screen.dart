import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({required this.chatId, super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msg = TextEditingController();
  final _firestore = FirestoreService();
  final _sc = ScrollController();
  bool _quickGiven = false;
  bool _completed = false;
  String? _otherUid;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  @override
  void dispose() { _msg.dispose(); _sc.dispose(); super.dispose(); }

  Future<void> _loadChatInfo() async {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final u = context.read<AuthProvider>().user;
    final participants = List<String>.from(data['participants'] ?? []);
    _otherUid = participants.firstWhere((id) => id != u?.uid, orElse: () => '');
    setState(() {
      _quickGiven = data['quickResponseGiven'] ?? false;
      _completed = data['orderCompleted'] ?? false;
    });
  }

  Future<void> _giveQuickResponse(String senderId) async {
    if (_quickGiven || _otherUid == null || _otherUid!.isEmpty) return;
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    final createdAt = chatDoc.data()?['createdAt'] != null ? DateTime.parse(chatDoc.data()!['createdAt']) : DateTime.now();
    if (DateTime.now().difference(createdAt).inMinutes <= 5) {
      await _addRating(_otherUid!);
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'quickResponseGiven': true});
      setState(() => _quickGiven = true);
    }
  }

  Future<void> _confirmOrder() async {
    if (_completed || _otherUid == null || _otherUid!.isEmpty) return;
    final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Подтвердить выполнение?'),
      content: const Text('Исполнитель получит +1 к рейтингу.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Подтвердить', style: TextStyle(color: Colors.green))),
      ],
    ));
    if (confirm == true) {
      await _addRating(_otherUid!);
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'orderCompleted': true});
      setState(() => _completed = true);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Выполнение подтверждено! +1 к рейтингу')));
    }
  }

  Future<void> _addRating(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    final completed = (data['completedOrders'] ?? 0) + 1;
    final total = (data['totalRatings'] ?? 0) + 1;
    final rating = total > 0 ? (completed / total * 5.0).clamp(0.0, 5.0) : 0.0;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'completedOrders': completed,
      'totalRatings': total,
      'rating': double.parse(rating.toStringAsFixed(1)),
    });
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Чат'), actions: [
        if (!_completed && _otherUid != null && _otherUid!.isNotEmpty)
          TextButton.icon(onPressed: _confirmOrder, icon: const Icon(Icons.check_circle, color: Colors.green), label: const Text('Выполнено')),
      ]),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp', descending: false).snapshots(),
          builder: (_, s) {
            if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!s.hasData || s.data!.docs.isEmpty) return const Center(child: Text('Нет сообщений. Напишите первым!'));
            final msgs = s.data!.docs;
            WidgetsBinding.instance.addPostFrameCallback((_) { if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });
            return ListView.builder(controller: _sc, itemCount: msgs.length, itemBuilder: (_, i) {
              final d = msgs[i].data() as Map<String, dynamic>;
              final me = d['senderId'] == u.uid;
              return Align(alignment: me ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), decoration: BoxDecoration(color: me ? Colors.orange.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Text(d['text'] ?? '', style: const TextStyle(fontSize: 16))));
            });
          },
        )),
        Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _msg, decoration: const InputDecoration(hintText: 'Сообщение...', border: OutlineInputBorder()), onSubmitted: (_) => _send(u.uid))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send, color: Colors.orange), onPressed: () => _send(u.uid)),
        ])),
      ]),
    );
  }

  Future<void> _send(String uid) async {
    final t = _msg.text.trim(); if (t.isEmpty) return;
    await _firestore.sendMessage(widget.chatId, Message(id: DateTime.now().millisecondsSinceEpoch.toString(), senderId: uid, text: t, timestamp: DateTime.now()));
    _msg.clear();
    await _giveQuickResponse(uid);
  }
}
