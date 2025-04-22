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
          'Settings',
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
            leading: Icon(Icons.person, color: Colors.green.shade700),
            title: Text('Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Manage your account details'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.notifications, color: Colors.green.shade700),
            title: Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Manage notification settings'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.lock, color: Colors.green.shade700),
            title: Text('Privacy & Security', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Adjust your privacy settings'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.palette, color: Colors.green.shade700),
            title: Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Customize the app’s look'),
            onTap: () {},
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.family_restroom, color: Colors.green.shade700),
            title: Text('Manage Linked Adults', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Add or view your connected adults'),
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
            title: Text('Log out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Log out from the app'),
            onTap: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context, 
                MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.info, color: Colors.green.shade700),
            title: Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            subtitle: Text('Learn more about SproutQuest'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
