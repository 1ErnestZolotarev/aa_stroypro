import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
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
  bool _rated = false;
  bool _quickResponseGiven = false;

  @override
  void initState() {
    super.initState();
    _checkQuickResponse();
  }

  @override
  void dispose() { _msg.dispose(); _sc.dispose(); super.dispose(); }

  Future<void> _checkQuickResponse() async {
    final doc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    if (doc.exists) {
      setState(() => _quickResponseGiven = doc.data()?['quickResponseGiven'] ?? false);
    }
  }

  Future<void> _giveQuickResponseIfNeeded(String senderId) async {
    if (_quickResponseGiven) return;
    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
    if (!chatDoc.exists) return;
    final data = chatDoc.data()!;
    final participants = List<String>.from(data['participants'] ?? []);
    final otherUid = participants.firstWhere((id) => id != senderId, orElse: () => '');
    if (otherUid.isEmpty) return;
    final chatCreatedAt = data['createdAt'] != null ? DateTime.parse(data['createdAt']) : DateTime.now();
    if (DateTime.now().difference(chatCreatedAt).inMinutes <= 5) {
      await _addRating(otherUid, 'quickResponses');
      await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({'quickResponseGiven': true});
      setState(() => _quickResponseGiven = true);
    }
  }

  Future<void> _addRating(String uid, String type) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!doc.exists) return;
    final user = AppUser.fromMap(doc.data()!);
    int quick = user.quickResponses, completed = user.completedOrders, thanks = user.thanks, noshows = user.noShows;
    if (type == 'completedOrders') completed++; else if (type == 'thanks') thanks++; else if (type == 'quickResponses') quick++;
    final totalPoints = quick + completed + thanks - (noshows * 2);
    final totalActions = quick + completed + thanks + noshows;
    final newRating = totalActions > 0 ? (totalPoints / totalActions).clamp(0.0, 5.0) : 0.0;
    await FirebaseFirestore.instance.collection('users').doc(uid).update({type: FieldValue.increment(1), 'rating': newRating, 'totalRatings': FieldValue.increment(1)});
  }

  Future<void> _manualRate(String otherUid, String type) async {
    await _addRating(otherUid, type);
    setState(() => _rated = true);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Оценка учтена!')));
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<AuthProvider>().user!;
    return Scaffold(
      appBar: AppBar(title: const Text('Чат'), actions: [
        PopupMenuButton<String>(icon: const Icon(Icons.star, color: Colors.amber), tooltip: 'Оценить', onSelected: (v) async {
          final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).get();
          final participants = List<String>.from(chatDoc.data()!['participants'] ?? []);
          final otherUid = participants.firstWhere((id) => id != u.uid, orElse: () => '');
          if (otherUid.isEmpty) return;
          _manualRate(otherUid, v);
        }, itemBuilder: (_) => [
          const PopupMenuItem(value: 'completedOrders', child: ListTile(leading: Icon(Icons.check_circle, color: Colors.green), title: Text('Заказ выполнен (+1)'))),
          const PopupMenuItem(value: 'thanks', child: ListTile(leading: Icon(Icons.favorite, color: Colors.red), title: Text('Сказать спасибо (+1)'))),
          const PopupMenuItem(value: 'noShows', child: ListTile(leading: Icon(Icons.person_off, color: Colors.orange), title: Text('Не пришёл (-2)'))),
        ]),
      ]),
      body: Column(children: [
        if (!_rated) Container(padding: const EdgeInsets.all(8), color: Colors.amber.shade50, child: Row(children: [const Icon(Icons.info_outline, size: 16, color: Colors.amber), const SizedBox(width: 8), Expanded(child: Text(_quickResponseGiven ? 'Оцените результат работы' : 'Быстрый ответ (до 5 мин) — автоматический +1', style: const TextStyle(fontSize: 12)))])),
        Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp', descending: false).snapshots(), builder: (_, s) {
          if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!s.hasData || s.data!.docs.isEmpty) return const Center(child: Text('Нет сообщений'));
          final msgs = s.data!.docs;
          WidgetsBinding.instance.addPostFrameCallback((_) { if (_sc.hasClients) _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); });
          return ListView.builder(controller: _sc, itemCount: msgs.length, itemBuilder: (_, i) {
            final d = msgs[i].data() as Map<String, dynamic>;
            final me = d['senderId'] == u.uid;
            return Align(alignment: me ? Alignment.centerRight : Alignment.centerLeft, child: Container(margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8), padding: const EdgeInsets.all(12), constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7), decoration: BoxDecoration(color: me ? Colors.orange.shade100 : Colors.grey.shade200, borderRadius: BorderRadius.circular(12)), child: Text(d['text'] ?? '', style: const TextStyle(fontSize: 16))));
          });
        })),
        Padding(padding: const EdgeInsets.all(8), child: Row(children: [Expanded(child: TextField(controller: _msg, decoration: const InputDecoration(hintText: 'Сообщение...', border: OutlineInputBorder()), onSubmitted: (_) => _send(u.uid))), const SizedBox(width: 8), IconButton(icon: const Icon(Icons.send, color: Colors.orange), onPressed: () => _send(u.uid))])),
      ]),
    );
  }

  Future<void> _send(String uid) async {
    final t = _msg.text.trim(); if (t.isEmpty) return;
    try { await _firestore.sendMessage(widget.chatId, Message(id: DateTime.now().millisecondsSinceEpoch.toString(), senderId: uid, text: t, timestamp: DateTime.now())); _msg.clear(); await _giveQuickResponseIfNeeded(uid); } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e'))); }
  }
}
