import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
              // SproutQuest text
              Text(
                'SproutQuest',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 20),

              // -------------------------------------------------------------------

              // "Are you ready to save the planet?" text
              Text(
                'Are you ready to save the planet?',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              SizedBox(height: 40),

              // ---------------------------------------------------------------------
              // Email input
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 20),

              // Password input
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              SizedBox(height: 20),

              // -------------------------------------------------------
              // Login button
              ElevatedButton(
                onPressed: () {
                  // Handle login action
                  print("Logging in...");

                  // Go to home screen
                  Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()
                    ),
                  );
                },
                child: Text('Login'),
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 50)),
                  backgroundColor: MaterialStateProperty.all(Colors.green.shade700), // Correct way to set background color
                  foregroundColor: MaterialStateProperty.all(Colors.white),  // Set text color to white
                  textStyle: MaterialStateProperty.all(TextStyle(fontSize: 18)),
                ),
              ),

              SizedBox(height: 20),

              // ---------------------------------------------------------
              // Forgot password link
              TextButton(
                onPressed: () {
                  // Navigate to forgot password screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot your password?',
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
