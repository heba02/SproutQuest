import 'package:flutter/material.dart';
import 'pending_missions_screen.dart';
import 'adult_settings_screen.dart';

class AdultMainScreen extends StatefulWidget {
  const AdultMainScreen({super.key});

  @override
  State<AdultMainScreen> createState() => _AdultMainScreenState();
}

class _AdultMainScreenState extends State<AdultMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    PendingMissionsScreen(),
    AdultSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 12,
        ),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Pending Missions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
