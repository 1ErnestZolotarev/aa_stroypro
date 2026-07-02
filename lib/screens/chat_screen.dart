import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart' as OurAuth;
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

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  Future<void> _markRead() async {
    final u = context.read<OurAuth.AuthProvider>().user;
    if (u == null) return;
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastReadBy.${u.phone}': DateTime.now().toIso8601String(),
    });
  }

  @override
  void dispose() {
    _msg.dispose();
    _sc.dispose();
    super.dispose();
  }

  Future<void> _showOptionsDialog(String messageId, String currentText) async {
    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Действие с сообщением'),
        content: const Text('Выберите, что сделать:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'edit'),
            child: const Text('Редактировать'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      await _showEditDialog(messageId, currentText);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Удалить сообщение?'),
          content: const Text('Это действие необратимо.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _firestore.deleteMessage(widget.chatId, messageId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Сообщение удалено')),
        );
      }
    }
  }

  Future<void> _showEditDialog(String messageId, String currentText) async {
    final controller = TextEditingController(text: currentText);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Редактировать сообщение'),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text('Сохранить')),
        ],
      ),
    );
    if (result != null && result != currentText) {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(widget.chatId)
          .collection('messages')
          .doc(messageId)
          .update({'text': result, 'edited': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = context.read<OurAuth.AuthProvider>().user!;
    final isAdmin = u.isAdmin;
    return Scaffold(
      appBar: AppBar(title: const Text('Чат')),
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('messages').orderBy('timestamp', descending: false).snapshots(),
          builder: (_, s) {
            if (s.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!s.hasData || s.data!.docs.isEmpty) return const Center(child: Text('Нет сообщений. Напишите первым!'));
            final msgs = s.data!.docs;
            Future.delayed(const Duration(milliseconds: 100), () {
              if (_sc.hasClients) {
                _sc.animateTo(_sc.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
              }
            });
            return ListView.builder(
              controller: _sc,
              itemCount: msgs.length,
              itemBuilder: (_, i) {
                final d = msgs[i].data() as Map<String, dynamic>;
                final me = d['senderId'] == u.phone;
                final edited = d['edited'] == true;
                final text = d['text'] ?? '';
                final messageId = msgs[i].id;
                final senderName = d['senderName'] ?? d['senderId'] ?? 'Пользователь';

                Widget messageBubble = Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                  decoration: BoxDecoration(
                    color: me ? Colors.orange.shade100 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!me)
                        Text(
                          senderName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blueGrey),
                        ),
                      const SizedBox(height: 4),
                      Text(text, style: const TextStyle(fontSize: 16)),
                      if (edited) const Text('(отредактировано)', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                );

                if (isAdmin) {
                  return GestureDetector(
                    onLongPress: () => _showOptionsDialog(messageId, text),
                    child: Align(
                      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                      child: messageBubble,
                    ),
                  );
                } else {
                  return Align(
                    alignment: me ? Alignment.centerRight : Alignment.centerLeft,
                    child: messageBubble,
                  );
                }
              },
            );
          },
        )),
        Padding(padding: const EdgeInsets.all(8), child: Row(children: [
          Expanded(child: TextField(controller: _msg, decoration: const InputDecoration(hintText: 'Сообщение...', border: OutlineInputBorder()), onSubmitted: (_) => _send(u))),
          const SizedBox(width: 8),
          IconButton(icon: const Icon(Icons.send, color: Colors.orange), onPressed: () => _send(u)),
        ])),
      ]),
    );
  }

  Future<void> _send(AppUser user) async {
    final t = _msg.text.trim(); if (t.isEmpty) return;
    final message = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: user.phone,
      senderName: user.name,
      text: t,
      timestamp: DateTime.now(),
    );
    await _firestore.sendMessage(widget.chatId, message);
    _msg.clear();
    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'lastReadBy.${user.phone}': DateTime.now().toIso8601String(),
    });
  }
}
