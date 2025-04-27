import 'package:flutter/material.dart';
import 'package:sproutquest/screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'manage_linked_adults_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD), // Matching background color
      appBar: AppBar(
        title: Text(
          'Inställningar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: Colors.green.shade700,
            size: 35), // Makes back arrow match theme
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          

          ListTile(
            leading: Icon(Icons.notifications, color: Colors.green.shade700),
            title: Text('Notiser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Hantera notiser'),
            onTap: () {},
          ),
          Divider(),

          

          ListTile(
            leading: Icon(Icons.palette, color: Colors.green.shade700),
            title: Text('Utseende', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Ändra appens utseende'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.family_restroom, color: Colors.green.shade700),
            title: Text('Hantera länkade vuxna', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Lägg till eller visa dina länkade vuxna'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ManageLinkedAdultsScreen(),
                ),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.waving_hand, color: Colors.green.shade700),
            title: Text('Logga ut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Logga ut från appen'),
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
