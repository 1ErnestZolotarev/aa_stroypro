import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import 'email_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _cityCtrl;
  String _role = 'customer';
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    _cityCtrl = TextEditingController(text: user?.city ?? '');
    _role = user?.role ?? 'customer';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);

      try {
        await context.read<AuthProvider>().updateProfile(
              name: _nameCtrl.text,
              phone: _phoneCtrl.text,
              city: _cityCtrl.text,
              role: _role,
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль обновлён!')),
          );
          setState(() => _isEditing = false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSaving = false);
        }
      }
    }
  }

  /// Открывает почтовый клиент для обратной связи
  Future<void> _sendFeedback() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ernest779977@gmail.com',
      queryParameters: {
        'subject': 'ААСтройПро - Обратная связь',
        'body': 'Здравствуйте!\n\n'
            'Хочу сообщить:\n'
            '\n'
            '\n'
            '---\n'
            'Отправлено из приложения ААСтройПро',
      },
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось открыть почтовый клиент')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Пользователь не найден')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => setState(() => _isEditing = false),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.orange.shade100,
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 40, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 24),
              // Email статус
              Card(
                child: ListTile(
                  leading: const Icon(Icons.email),
                  title: const Text('Email'),
                  subtitle: Text(auth.currentEmail ?? 'Не привязан'),
                  trailing: auth.hasEmailProvider
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EmailScreen(isLinking: true),
                            ),
                          ),
                          child: const Text('Привязать'),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  prefixIcon: Icon(Icons.person),
                ),
                enabled: _isEditing,
                validator: (v) => v!.isEmpty ? 'Введите имя' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                enabled: _isEditing,
                validator: (v) => v!.isEmpty ? 'Введите телефон' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityCtrl,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  prefixIcon: Icon(Icons.location_city),
                ),
                enabled: _isEditing,
                validator: (v) => v!.isEmpty ? 'Введите город' : null,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'customer', label: Text('Заказчик')),
                  ButtonSegment(value: 'executor', label: Text('Исполнитель')),
                ],
                selected: {_role},
                onSelectionChanged: _isEditing
                    ? (s) => setState(() => _role = s.first)
                    : null,
              ),
              const SizedBox(height: 32),
              if (_isEditing)
                _isSaving
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Сохранить'),
                        onPressed: _saveProfile,
                      ),
              const SizedBox(height: 24),
              const Divider(),
              // Обратная связь
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: const Text('Написать разработчику'),
                subtitle: const Text('Сообщить об ошибке или предложить идею'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _sendFeedback,
              ),
              // Версия приложения
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Версия'),
                subtitle: const Text('1.0.0'),
              ),
              const Divider(),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Выйти', style: TextStyle(color: Colors.red)),
                onPressed: () async {
                  await auth.logout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
