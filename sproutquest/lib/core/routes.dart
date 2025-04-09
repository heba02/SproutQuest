import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import '../screens/forgot_password_screen.dart';

Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => LoginScreen(),
  '/forgot-password': (context) => ForgotPasswordScreen(),
};
