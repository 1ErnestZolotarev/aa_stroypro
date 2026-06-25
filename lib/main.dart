import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
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
  try { await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _onlineTimer;

  @override
  void initState() {
    super.initState();
    _startOnlineTimer();
  }

  void _startOnlineTimer() {
    _onlineTimer = Timer.periodic(const Duration(seconds: 30), (_) {
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
    providers: [ChangeNotifierProvider(create: (_) => OurAuth.AuthProvider()), ChangeNotifierProvider(create: (_) => OrderProvider())],
    child: MaterialApp(
      title: 'ААСтройПро', theme: ThemeData(primarySwatch: Colors.orange), debugShowCheckedModeBanner: false,
      home: Consumer<OurAuth.AuthProvider>(builder: (_, a, __) => a.user != null
        ? AdaptiveLayout(mobileBody: const HomeScreen(), tabletBody: const Row(children: [Expanded(flex:2, child: HomeScreen()), VerticalDivider(width:1), Expanded(flex:3, child: Center(child: Text('Выберите объявление')))]))
        : const StartScreen()),
      routes: {
        '/create_order': (_) => const CreateOrderScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/register': (_) => const RegisterScreen(),
        '/login': (_) => const LoginScreen(),
      },
    ),
  );
}
