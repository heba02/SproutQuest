import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Create a global RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SproutQuest',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      navigatorObservers: [routeObserver], // 👈 Add the observer here
      home: LoginScreen(), // Set the login screen as the home screen
    );
  }
}
