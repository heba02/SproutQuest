import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'manage_linked_children_screen.dart';
import 'login_screen.dart';

class AdultSettingsScreen extends StatelessWidget {
  const AdultSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green.shade700,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          ListTile(
            leading: Icon(Icons.family_restroom, color: Colors.green.shade700),
            title: Text('Manage Linked Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageLinkedChildrenScreen()),
              );
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.green.shade700),
            title: Text('Log Out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}
