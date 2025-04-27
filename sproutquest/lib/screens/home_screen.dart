import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

ButtonStyle buttonStyle() {
  return ButtonStyle(
    padding: WidgetStateProperty.all(
        EdgeInsets.symmetric(vertical: 16, horizontal: 24)),
    backgroundColor: WidgetStateProperty.all(Colors.green.shade700),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    textStyle: WidgetStateProperty.all(TextStyle(fontSize: 18)),
  );
}

Future<Map<String, String>> fetchTodayMissions() async {
  final firestore = FirebaseFirestore.instance;
  final today = DateTime.now();
  final todayId = '${today.year}-${today.month}-${today.day}';

  final dailyDoc = firestore.collection('daily_missions').doc(todayId);
  final dailySnapshot = await dailyDoc.get();

  if (dailySnapshot.exists) {
    final data = dailySnapshot.data()!;
    return {
      'battery': data['battery'],
      'pant': data['pant'],
      'trash': data['trash'],
    };
  } else {
    final categories = ['battery', 'pant', 'trash'];
    Map<String, String> selectedMissions = {};

    for (String category in categories) {
      final challengeSnapshot = await firestore.collection('challenges').doc(category).get();
      if (challengeSnapshot.exists) {
        final data = challengeSnapshot.data()!;
        final missions = data.values.toList();
        if (missions.isNotEmpty) {
          missions.shuffle();
          selectedMissions[category] = missions.first;
        }
      }
    }

    await dailyDoc.set({
      'battery': selectedMissions['battery'],
      'pant': selectedMissions['pant'],
      'trash': selectedMissions['trash'],
      'date': todayId,
    });
    return selectedMissions;
  }
}


Future<void> _submitMission(String missionTitle, BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final missionsRef = firestore.collection('missions');
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  final existingMissions = await missionsRef
      .where('childId', isEqualTo: user.uid)
      .where('missionTitle', isEqualTo: missionTitle)
      //.where('status', whereIn: ['pending', 'approved'])
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .get();

  if (existingMissions.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You have already submitted or completed this mission! ✋')),
    );
    return;
  }

  // 2. Hämta kopplade vuxna
  final userDoc = await firestore.collection('users').doc(user.uid).get();
  final List<dynamic> linkedAdultsRaw = userDoc.data()?['linkedAdults'] ?? [];

  if (linkedAdultsRaw.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('No linked adults found. Please add an adult first.')),
    );
    return;
  }

  List<Map<String, dynamic>> linkedAdults = linkedAdultsRaw.cast<Map<String, dynamic>>();
  List<Map<String, dynamic>> selectedAdults = [];

  // 3. Visa en dialog där barnet kan välja vuxna
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Select Approvers'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: linkedAdults.map((adult) {
                  final isSelected = selectedAdults.contains(adult);
                  return CheckboxListTile(
                    title: Text(adult['name'] ?? adult['email']),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          selectedAdults.add(adult);
                        } else {
                          selectedAdults.remove(adult);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Stäng utan val
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Bekräfta val
            },
            child: Text('Submit'),
          ),
        ],
      );
    },
  );

  if (selectedAdults.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Mission submission cancelled.')),
    );
    return;
  }

  // 4. Skapa mission i Firestore
  final missionDoc = missionsRef.doc();

  await missionDoc.set({
    'childId': user.uid,
    'childEmail': user.email,
    'missionTitle': missionTitle,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
    'approvers': selectedAdults.map((adult) => adult['email']).toList(),
    'approvedBy': [],
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Mission submitted for approval! 🌱')),
  );

  // 5. Lägg till barnet i varje vald vuxens linkedChildren om det inte redan finns
  for (final adult in selectedAdults) {
    final adultEmail = adult['email'];

    final adultQuery = await firestore
        .collection('users')
        .where('email', isEqualTo: adultEmail)
        .limit(1)
        .get();

    if (adultQuery.docs.isNotEmpty) {
      final adultDoc = adultQuery.docs.first;
      final adultDocRef = adultDoc.reference;

      final List<dynamic> linkedChildren = adultDoc.data()['linkedChildren'] ?? [];

      final alreadyLinked = linkedChildren.any((child) => child['childEmail'] == user.email);

      if (!alreadyLinked) {
        await adultDocRef.update({
          'linkedChildren': FieldValue.arrayUnion([
            {
              'childEmail': user.email,
              'displayName': user.email,
            }
          ]),
        });
      }
    }
  }
}



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userScore = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserScore();
  }

  Future<void> _fetchUserScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userScore = (doc.data()?['score'] ?? 0) as int;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD), // Matching background color
      body: FutureBuilder<Map<String, String>>(
        future: fetchTodayMissions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading missions'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No missions available today'));
          } else {
            final missions = snapshot.data!;

            return Padding(
              padding: const EdgeInsets.only(top: 75, left: 24, right: 24, bottom: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.emoji_events, color: Colors.green.shade800, size: 28),
                                SizedBox(width: 12),
                                Text(
                                  'Your score: $_userScore',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  Text(
                    'Your daily missions:',
                    style: TextStyle(
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () {
                      _submitMission(missions['battery']!, context);
                    },
                    style: buttonStyle(),
                    child: Text(
                      missions['battery']!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _submitMission(missions['pant']!, context);
                    },
                    style: buttonStyle(),
                    child: Text(
                      missions['pant']!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _submitMission(missions['trash']!, context);
                    },
                    style: buttonStyle(),
                    child: Text(
                      missions['trash']!,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          }
        },
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
