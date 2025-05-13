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
        title: Text('Inställningar',
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
            leading: Icon(Icons.family_restroom, color: Colors.green.shade700),
            title: Text('Hantera länkade barn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageLinkedChildrenScreen()),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.person, color: Colors.green.shade700),
            title: Text('Konto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Hantera dina konto-inställningar'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.notifications, color: Colors.green.shade700),
            title: Text('Notiser', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Hantera notiser'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.lock, color: Colors.green.shade700),
            title: Text('Integritet & Säkerhet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Ändra dina sekretessinställningar'),
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
            leading: Icon(Icons.info, color: Colors.green.shade700),
            title: Text('Om', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Lär dig mer om SproutQuest'),
            onTap: () {},
          ),

          ListTile(
            leading: Icon(Icons.logout, color: Colors.green.shade700),
            title: Text('Logga ut', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
