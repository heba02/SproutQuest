import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sproutquest/screens/forgot_password_screen.dart';

void main() {
  testWidgets('ForgotPasswordScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordScreen()),
    );

    expect(
      find.text('Enter your email and we will send you a reset link!'),
      findsOneWidget,
    );
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);
    expect(find.text('Back to login'), findsOneWidget);
  });

  testWidgets('User can enter email', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: ForgotPasswordScreen()),
    );

    await tester.enterText(find.byType(TextFormField), 'test@example.com');
    expect(find.text('test@example.com'), findsOneWidget);
  });
}
