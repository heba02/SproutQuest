import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/forgot_password_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SproutQuest',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LoginScreen(), // Set the login screen as the home screen
    );
  }
}
