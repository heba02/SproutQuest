import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sproutquest/screens/adult_main_screen.dart';



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

      print("Inloggad som: ${userCredential.user?.email}");

      final user = FirebaseAuth.instance.currentUser;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        final role = snapshot.data()!['role'];

        if (role == 'child') {
          Navigator.pushReplacement(
            context, 
            MaterialPageRoute(builder: (context) => HomeScreen()),
            );
        } else if (role == 'adult') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdultMainScreen()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Du måste välja en roll för ditt konto')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Användardata hittades inte')),
        );
      }
    } catch (e) {
      print ('Inloggningen misslyckades');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Inloggning misslyckades. Vänligen kontrollera dina inloggningsuppgifter.')),
      );
    }
  }

  @override
  void dispose() {
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
                'Är du redo att rädda planeten?',
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
                  labelText: 'E-post',
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
                  labelText: 'Lösenord',
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
                  padding: WidgetStateProperty.all(
                    EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                  ),
                  backgroundColor: WidgetStateProperty.all(
                    Colors.green.shade700,
                  ), // Correct way to set background color
                  foregroundColor: WidgetStateProperty.all(
                    Colors.white,
                  ), // Set text color to white
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text('Logga in'),
              ),

              SizedBox(height: 20),

              // ---------------------------------------------------------
              // Sign-up button

              TextButton(

                onPressed: () {
                  // Navigate to forgot password screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SignUpScreen(),
                    ),
                  );
                },
                child: Text(
                  "Har du inget konto? Registrera dig.",
                  style: TextStyle(color: Colors.green.shade700),
                ),
              ),

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
                  'Glömt ditt lösenord?',
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
