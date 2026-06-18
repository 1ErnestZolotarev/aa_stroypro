import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/order_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_order_screen.dart';
import 'widgets/adaptive_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InitScreen());
}

class InitScreen extends StatefulWidget {
  const InitScreen({super.key});

  @override
  State<InitScreen> createState() => _InitScreenState();
}

class _InitScreenState extends State<InitScreen> {
  String _status = 'Инициализация...';

  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      setState(() => _status = 'Подключение к Firebase...');
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Firebase init timeout'),
      );
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Ошибка: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!_status.startsWith('Ошибка'))
                  const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  _status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                if (_status.startsWith('Ошибка')) ...[
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _status = 'Инициализация...');
                      _initFirebase();
                    },
                    child: const Text('Повторить'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'ААСтройПро',
        theme: ThemeData(primarySwatch: Colors.orange),
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (ctx, auth, _) {
            if (auth.user != null) {
              return AdaptiveLayout(
                mobileBody: const HomeScreen(),
                tabletBody: const Row(
                  children: [
                    Expanded(flex: 2, child: HomeScreen()),
                    VerticalDivider(width: 1),
                    Expanded(
                      flex: 3,
                      child: Center(child: Text('Выберите объявление')),
                    ),
                  ],
                ),
              );
            } else {
              return const LoginScreen();
            }
          },
        ),
        routes: {
          '/create_order': (_) => const CreateOrderScreen(),
        },
      ),
    );
  }
}
