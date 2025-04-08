import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sproutquest/screens/login_screen.dart';
import 'package:sproutquest/screens/home_screen.dart';
import 'package:sproutquest/screens/forgot_password_screen.dart';

void main() {
  testWidgets('LoginScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
      ),
    );

    expect(find.text('SproutQuest'), findsOneWidget);
    expect(find.text('Are you ready to save the planet?'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(find.byIcon(Icons.email), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);
  });

  testWidgets('User can enter email and password', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen()),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'user@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');

    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('password123'), findsOneWidget);
  });

  testWidgets('Tapping Login navigates to HomeScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
        },
      ),
    );

    // Tap the login button
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    // Should now find HomeScreen content
    expect(find.textContaining('Your daily missions:'), findsOneWidget);
  });

  testWidgets('Tapping "Forgot your password?" navigates to ForgotPasswordScreen',
          (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: LoginScreen(),
            routes: {
              '/forgot-password': (context) => ForgotPasswordScreen(),
            },
          ),
        );

        await tester.tap(find.text('Forgot your password?'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Enter your email...'), findsOneWidget);
      });
}
