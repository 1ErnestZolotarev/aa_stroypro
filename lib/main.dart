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
  @override
  void initState() {
    super.initState();
    _initFirebase();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Ошибка'),
            content: Text('$e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Загрузка...'),
            ],
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
