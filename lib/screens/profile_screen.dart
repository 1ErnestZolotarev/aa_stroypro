import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().updateLastSeen();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    if (user == null) return const Scaffold(body: Center(child: Text('Не авторизован')));

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Имя: ${user.name}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Телефон: ${user.phone}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Город: ${user.city}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Роль: ${user.role}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Статус: ${user.isAdmin ? "Администратор" : "Пользователь"}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Забанен до: ${user.bannedUntil?.toLocal().toString() ?? "Нет"}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            if (user.isAdmin)
              Column(
                children: [
                  ElevatedButton(
                    onPressed: () => _showBanDialog(context),
                    child: const Text('Забанить пользователя'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => _showUnbanDialog(context),
                    child: const Text('Разбанить пользователя'),
                  ),
                ],
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                await auth.logout();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Выйти'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBanDialog(BuildContext context) {
    final phoneController = TextEditingController();
    final hoursController = TextEditingController(text: '24');
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Забанить пользователя'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
            TextField(controller: hoursController, decoration: const InputDecoration(labelText: 'Часы')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              final hours = int.tryParse(hoursController.text.trim()) ?? 24;
              if (phone.isEmpty) return;
              await AuthService().banUser(phone, hours);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Пользователь $phone забанен на $hours ч')),
              );
            },
            child: const Text('Забанить'),
          ),
        ],
      ),
    );
  }

  void _showUnbanDialog(BuildContext context) {
    final phoneController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Разбанить пользователя'),
        content: TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Телефон')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () async {
              final phone = phoneController.text.trim();
              if (phone.isEmpty) return;
              await AuthService().unbanUser(phone);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Пользователь $phone разбанен')),
              );
            },
            child: const Text('Разбанить'),
          ),
        ],
      ),
    );
  }
}
