import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _userName = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  String _selectedRole = 'child';

  Future<bool> _userNameCheck(String usrNme) async {
    final querySnapshot = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: usrNme).get();

    if(querySnapshot.docs.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Användarnamn används redan. Vänligen välj ett annat användarnamn.')),
      );
      return true;
    }
    return false;
  }

  Future<void> _signUp() async {
    String email = _emailController.text.trim();
    String username = _userName.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lösenorden matchar ej!')),
      );
      return;
    }

    // username checking. If it already is used or not.
    bool userNameisTaken = await _userNameCheck(username);
    if (userNameisTaken) {
      return;
    }

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = FirebaseAuth.instance.currentUser;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user!.uid);

      await userDoc.set({
        'username': username,
        'email': user.email,
        'role': _selectedRole,
        'score': _selectedRole == 'child' ? 0 : null,
      });

      print("Konto skapades: ${userCredential.user?.email}");
      Navigator.pushReplacementNamed(context, '/');
    } catch (e) {
      print('Registreringen misslyckades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registreringen misslyckades. Vänligen försök igen.')),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      backgroundColor: Color(0xFFDAD7CD),
      appBar: AppBar(
        title: Text("Skapa konto"),
        backgroundColor: Colors.green.shade700,
      ),
      body: SingleChildScrollView (
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Registrera dig',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 30),
            TextFormField(
              controller: _userName,
              decoration: InputDecoration(
                labelText: 'Användarnamn',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 20),
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
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Bekräfta lösenord',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _signUp,
              style: ButtonStyle(
                padding: WidgetStateProperty.all(
                  EdgeInsets.symmetric(vertical: 16, horizontal: 50),
                ),
                backgroundColor: WidgetStateProperty.all(Colors.green.shade700),
                foregroundColor: WidgetStateProperty.all(Colors.white),
                textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
              ),
              child: Text('Registrera dig'),
            ),
            SizedBox(height: 20),
            Text(
              'Jag registrerar mig som:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text('Barn'),
              leading: Radio<String>(
                value: 'child',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ),
            ListTile(
              title: const Text('Vuxen'),
              leading: Radio<String>(
                value:'adult',
                groupValue: _selectedRole,
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}