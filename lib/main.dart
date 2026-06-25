import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as OurAuth;
import 'providers/order_provider.dart';
import 'screens/start_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/create_order_screen.dart';
import 'screens/profile_screen.dart';
import 'widgets/adaptive_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try { await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform); } catch (_) {}
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [ChangeNotifierProvider(create: (_) => OurAuth.AuthProvider()), ChangeNotifierProvider(create: (_) => OrderProvider())],
    child: MaterialApp(
      title: 'ААСтройПро',
      theme: ThemeData(primarySwatch: Colors.orange),
      debugShowCheckedModeBanner: false,
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
