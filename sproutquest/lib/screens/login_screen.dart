import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _saveInput() async {
    String email = _emailController.text;
    String password = _passwordController.text; 
    try {
      UserCredential userCredential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
      
      print("Logged in as: ${userCredential.user?.email}");
      Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()
                    ),
                  );
    } catch(e) {
      print('login failed');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Please check your credentials.')),
      );
    }
    print("Email: $email, Password: $password");
  }

  @override
  void dispose () {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
                onPressed: _saveInput,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 16, horizontal: 50)),
                  backgroundColor: WidgetStateProperty.all(Colors.green.shade700), // Correct way to set background color
                  foregroundColor: WidgetStateProperty.all(Colors.white),  // Set text color to white
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text('Login')
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
