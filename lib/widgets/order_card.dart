import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final VoidCallback onTap;

  const OrderCard({required this.order, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(order.title, maxLines: 1),
        subtitle: Text('${order.city} • Бюджет: ${order.budget} ₽'),
        trailing: Chip(
          label: Text(order.type == 'offer' ? 'Исполнитель' : 'Заказчик'),
        ),
        onTap: onTap,
      ),
    );
  }
}
