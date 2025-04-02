import 'package:flutter/material.dart';
import 'settings_screen.dart'; // Assuming you will have a settings screen
import 'leaderboard_screen.dart'; // Assuming you will have a leaderboard screen

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),  // Background color matching Login screen
      appBar: AppBar(
        title: Text(
          'SproutQuest',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // SproutQuest heading
              Text(
                'Welcome to SproutQuest!',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
      // Bottom navigation bar with icons only
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        items: [
          // Home button (Icon)
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home', // Label is still needed for semantics but won't display
          ),
          // Leaderboard button (Icon)
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard', // Label is still needed for semantics but won't display
          ),
          // Settings button (Icon)
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings', // Label is still needed for semantics but won't display
          ),
        ],
        onTap: (index) {
          // Handle button tap navigation
          switch (index) {
            case 0:
            // Home Button
              break;
            case 1:
            // Navigate to Leaderboard screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardScreen(),
                ),
              );
              break;
            case 2:
            // Navigate to Settings screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(),
                ),
              );
              break;
          }
        },
      ),
    );
  }
}
