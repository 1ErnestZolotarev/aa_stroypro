import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as OurAuth;
import 'providers/order_provider.dart';
import 'screens/start_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_order_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'widgets/adaptive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}

  // Запрос разрешения на уведомления
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Получение токена и сохранение при входе
  String? token = await messaging.getToken();
  print('FCM Token: $token');

  // Обработка уведомлений, когда приложение открыто
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // Можно показать локальное уведомление или SnackBar
  });

  // Обработка нажатия на уведомление (когда приложение было закрыто)
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final orderId = message.data['orderId'];
    if (orderId != null) {
      // Здесь можно навигировать на заказ
    }
  });

  runApp(MyApp(token: token));
}

class MyApp extends StatefulWidget {
  final String? fcmToken;
  const MyApp({super.key, this.fcmToken});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _onlineTimer;
  bool _timerStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_timerStarted) {
      _startOnlineTimer();
      _timerStarted = true;
    }
  }

  void _startOnlineTimer() {
    _onlineTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      final user = context.read<OurAuth.AuthProvider>().user;
      if (user != null && user.phone.isNotEmpty) {
        final docId = user.phone.replaceAll(RegExp(r'\D'), '');
        FirebaseFirestore.instance.collection('users').doc(docId).update({
          'lastSeen': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  @override
  void dispose() {
    _onlineTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => OurAuth.AuthProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
    ],
    child: MaterialApp(
      title: 'ААСтройПро',
      theme: ThemeData(primarySwatch: Colors.orange),
      debugShowCheckedModeBanner: false,
      home: Consumer<OurAuth.AuthProvider>(
        builder: (_, a, __) => a.user != null
            ? AdaptiveLayout(
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
              )
            : const StartScreen(),
      ),
      routes: {
        '/create_order': (_) => const CreateOrderScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
      },
    ),
  );
}
