import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../providers/auth_provider.dart';

class OrderCard extends StatelessWidget {
  final ServiceOrder order;
  final VoidCallback onTap;
  const OrderCard({required this.order, required this.onTap, super.key});

  String _fmt(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes} мин. назад';
    if (diff.inHours < 24) return '${diff.inHours} ч. назад';
    if (diff.inDays < 7) return '${diff.inDays} дн. назад';
    return '${d.day}.${d.month}.${d.year}';
  }

  @override
  Widget build(BuildContext c) {
    final u = context.read<AuthProvider>().user;
    final isFav = u?.favorites.contains(order.id) ?? false;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        title: Text(order.title, maxLines: 1),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${order.city} • Бюджет: ${order.budget} ₽'),
          Text(_fmt(order.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              if (order.status != "active") Text(order.status == "in_work" ? "В работе" : "Завершён", style: TextStyle(fontSize: 12, color: order.status == "in_work" ? Colors.orange : Colors.green)),
        ]),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey, size: 20),
              onPressed: () async {
                if (u == null) return;
                final favs = List<String>.from(u.favorites);
                if (isFav) { favs.remove(order.id); } else { favs.add(order.id); }
                await FirebaseFirestore.instance.collection('users').doc(u.uid).update({'favorites': favs});
              },
            ),
            Chip(label: Text(order.type == 'offer' ? 'Исполнитель' : 'Заказчик')),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}
