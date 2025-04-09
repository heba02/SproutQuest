import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD), // Matching background color
      body: Padding(
        padding: const EdgeInsets.only(top: 75, left: 24, right: 24, bottom: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SproutQuest heading
            Text(
              'Your daily missions:',
              style: TextStyle(
                fontSize: 35,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 40),
            // First full-width button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Button 1 action
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                  backgroundColor:
                  WidgetStateProperty.all(Colors.green.shade700),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text(
                  'Recycle at least 20 cans at your nearest recyling center',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Second full-width button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Button 2 action
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                  backgroundColor:
                  WidgetStateProperty.all(Colors.green.shade700),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text(
                  'Collect 10 different sorts of leaves in your nearest park/forest',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            SizedBox(height: 16),
            // Third full-width button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Button 3 action
                },
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                      EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
                  backgroundColor:
                  WidgetStateProperty.all(Colors.green.shade700),
                  foregroundColor: WidgetStateProperty.all(Colors.white),
                  shape: WidgetStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
                ),
                child: Text(
                  'Cook a vegan dinner using at least 3 vegetables that are in season',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
      // The bottom navigation bar remains as is...
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
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
            icon: Icon(Icons.add_chart),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeaderboardScreen(),
                ),
              );
              break;
            case 1:
            // Stay on Home
              break;
            case 2:
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
