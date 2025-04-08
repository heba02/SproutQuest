import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();

  ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Heading
              Text(
                'Enter your email and we will send you a reset link!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 40),

              // Email input for reset
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Enter your email...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),

              // Submit button
              ElevatedButton(
                onPressed: () {
                  // Handle reset password logic here
                  print("Sending password reset email...");
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 50)),
                  backgroundColor: WidgetStateProperty.all(Colors.green.shade700),  // Correct way to set background color
                  foregroundColor: WidgetStateProperty.all(Colors.white),  // Set text color to white
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text('Send reset link'),
              ),

              SizedBox(height: 20),

              // Back to login button
              TextButton(
                onPressed: () {
                  Navigator.pop(context);  // Navigate back to the login screen
                },
                child: Text(
                  'Back to login',
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
