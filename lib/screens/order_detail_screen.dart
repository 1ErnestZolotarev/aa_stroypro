import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import 'chat_screen.dart';

class OrderDetailScreen extends StatelessWidget {
  final ServiceOrder order;

  const OrderDetailScreen({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthProvider>().user;
    final isOwn = currentUser?.uid == order.authorId;

    return Scaffold(
      appBar: AppBar(title: Text(order.title)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Автор: ${order.authorName}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Город: ${order.city}'),
            const SizedBox(height: 8),
            Text('Бюджет: ${order.budget} ₽', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text(order.description),
            const SizedBox(height: 16),
            if (!isOwn && currentUser != null) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.phone),
                    label: Text(order.authorPhone),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('Написать'),
                    onPressed: () async {
                      final chatId = await FirestoreService().createOrGetChat(
                        currentUser.uid,
                        order.authorId,
                        orderId: order.id,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(chatId: chatId),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
            if (isOwn)
              const Text('Это ваше объявление', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
