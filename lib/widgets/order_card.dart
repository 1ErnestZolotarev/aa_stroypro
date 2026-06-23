import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final VoidCallback onTap;

  const OrderCard({required this.order, required this.onTap, super.key});

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} мин. назад';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} ч. назад';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} дн. назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(order.title, maxLines: 1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.city} • Бюджет: ${order.budget} ₽'),
            const SizedBox(height: 2),
            Text(
              _formatDate(order.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(order.type == 'offer' ? 'Исполнитель' : 'Заказчик'),
        ),
        onTap: onTap,
      ),
    );
  }
}
