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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Если уже инициализирован - игнорируем
  }
  
  runApp(const MyApp());
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
