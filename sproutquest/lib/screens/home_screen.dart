import 'package:flutter/material.dart';
import 'package:sproutquest/screens/mission_pending_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'battery_screen.dart';
import 'trash_screen.dart';
import 'pant_screen.dart';
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mission_done_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

ButtonStyle buttonStyle() {
  return ButtonStyle(
    padding: WidgetStateProperty.all(
      EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
    backgroundColor: WidgetStateProperty.all(Colors.green.shade700),
    foregroundColor: WidgetStateProperty.all(Colors.white),
    shape: WidgetStateProperty.all(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      final challengeSnapshot =
          await firestore.collection('challenges').doc(category).get();
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

Future<String> compressAndSaveMission(
  XFile pickedFile,
  String missionTitle,
  List<Map<String, dynamic>> selectedAdults,
) async {
  try {
    final File imageFile = File(pickedFile.path);
    final bytes = await imageFile.readAsBytes();

    // Decode, resize, and compress image
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) throw Exception('Could not decode image');
    final resized = img.copyResize(
      originalImage,
      width: 300,
    ); // Resize width to 300px
    final compressed = img.encodeJpg(
      resized,
      quality: 70,
    ); // Compress to 70% quality

    final base64Image = base64Encode(compressed); // Convert to base64

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('Ingen inloggad användare!');
      return '';
    }

    final firestore = FirebaseFirestore.instance;
    final missionsRef = firestore.collection('missions');
    final missionDoc = missionsRef.doc();

    await missionDoc.set({
      'childId': user.uid,
      'childEmail': user.email,
      'missionTitle': missionTitle,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
      'approvers': selectedAdults.map((adult) => adult['email']).toList(),
      'approvedBy': [],
      'proofImageBase64': base64Image, // Store the base64 string here
    });

    print('Uppdrag med base64 foto sparat!');
    return base64Image;
  } catch (e) {
    print('Fel uppstod när uppdraget skulle sparas: $e');
    return '';
  }
}

Future<void> submitMissionWithPhoto(
  String missionTitle,
  BuildContext context,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final missionsRef = firestore.collection('missions');
  final todayStart = DateTime.now();
  final startOfDay = DateTime(
    todayStart.year,
    todayStart.month,
    todayStart.day,
  );

  // Check for duplicate pending/approved mission
  final existingMissions =
      await missionsRef
          .where('childId', isEqualTo: user.uid)
          .where('missionTitle', isEqualTo: missionTitle)
          .where('status', whereIn: ['pending', 'approved'])
          .where(
            'timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .get();

  if (existingMissions.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Du har redan gjort denna utmaning!✋')),
    );
    return;
  }

  // 2. Pick image
  final picker = ImagePicker();
  final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
  if (pickedFile == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Uppdraget genomfördes ej — inget foto togs.')),
    );
    return;
  }

  final userDoc = await firestore.collection('users').doc(user.uid).get();
  final List<dynamic> linkedAdultsRaw = userDoc.data()?['linkedAdults'] ?? [];

  if (linkedAdultsRaw.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Inga länkade vuxna hittades. Vänligen länka en vuxen först.',
        ),
      ),
    );
    return;
  }

  List<Map<String, dynamic>> linkedAdults =
      linkedAdultsRaw
          .whereType<Map<String, dynamic>>()
          .where(
            (adult) =>
                adult['email'] != null && adult['email'].toString().isNotEmpty,
          )
          .toList();

  List<Map<String, dynamic>> selectedAdults = [];

  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Välj din godkännare'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children:
                    linkedAdults.map((adult) {
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Avbryt'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Skicka'),
          ),
        ],
      );
    },
  );

  if (selectedAdults.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Uppdraget skickades ej.')));
    return;
  }
  // Upload image and save mission details
  final base64Image = await compressAndSaveMission(
    pickedFile,
    missionTitle,
    selectedAdults,
  );

  // Ensure child is linked to each selected adult
  for (final adult in selectedAdults) {
    final adultEmail = adult['email'];

    final adultQuery =
        await firestore
            .collection('users')
            .where('email', isEqualTo: adultEmail)
            .limit(1)
            .get();

    if (adultQuery.docs.isNotEmpty) {
      final adultDoc = adultQuery.docs.first;
      final adultDocRef = adultDoc.reference;

      final List<dynamic> linkedChildren =
          adultDoc.data()['linkedChildren'] ?? [];

      final alreadyLinked = linkedChildren.any(
        (child) => child['childEmail'] == user.email,
      );

      if (!alreadyLinked) {
        await adultDocRef.update({
          'linkedChildren': FieldValue.arrayUnion([
            {'childEmail': user.email, 'displayName': user.email},
          ]),
        });
      }
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Utmaningen skickades med fotobevis! 🌱')),
  );

  // Navigate to pending screen after success
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => MissionPendingScreen(mission: missionTitle),
    ),
  );
}

Future<bool> isMissionApproved(String missionTitle, String userId) async {
  final firestore = FirebaseFirestore.instance;

  // Fetch the mission document for the specific mission
  final missionSnapshot =
      await firestore
          .collection('missions')
          .where('childId', isEqualTo: userId)
          .where('missionTitle', isEqualTo: missionTitle)
          .where('status', isEqualTo: 'approved')
          .get();

  print(
    "Fetched ${missionSnapshot.docs.length} missions for $missionTitle with status 'approved'",
  );

  return missionSnapshot.docs.isNotEmpty;
}

Future<bool> isMissionPending(String missionTitle, String userId) async {
  final firestore = FirebaseFirestore.instance;

  // Fetch the mission document for the specific mission
  final missionSnapshot =
      await firestore
          .collection('missions')
          .where('childId', isEqualTo: userId)
          .where('missionTitle', isEqualTo: missionTitle)
          .where('status', isEqualTo: 'pending')
          .get();

  print(
    "Fetched ${missionSnapshot.docs.length} missions for $missionTitle with status 'pending'",
  );

  return missionSnapshot.docs.isNotEmpty;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer when the screen becomes visible
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
    _fetchUserScoreAndApprovals(); // Refresh mission status here
  }

  @override
  void didPopNext() {
    // This method will be called when the user navigates back to this screen
    _fetchUserScoreAndApprovals(); // Refresh the mission status when coming back to the screen
  }

  @override
  void dispose() {
    _confettiController.dispose();
    // Unsubscribe from the route observer to avoid memory leaks
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  int _userScore = 0;

  bool isBatteryApproved = false;
  bool isPantApproved = false;
  bool isTrashApproved = false;

  bool isBatteryPending = false;
  bool isPantPending = false;
  bool isTrashPending = false;

  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _fetchUserScoreAndApprovals(); // Ensure score is fetched first
  }

  // Fetch the user score
  Future<void> _fetchUserScoreAndApprovals() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;
    final userDoc = await firestore.collection('users').doc(user.uid).get();
    final missions = await fetchTodayMissions();
    final todayStart = DateTime.now();
    final startOfDay = DateTime(
      todayStart.year,
      todayStart.month,
      todayStart.day,
    );

    setState(() {
      _userScore = (userDoc.data()?['score'] ?? 0) as int;
    });

    for (final entry in missions.entries) {
      final category = entry.key;
      final missionTitle = entry.value;

      final approvedSnapshot =
          await firestore
              .collection('missions')
              .where('childId', isEqualTo: user.uid)
              .where('missionTitle', isEqualTo: missionTitle)
              .where('status', isEqualTo: 'approved')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .limit(1)
              .get();

      final pendingSnapshot =
          await firestore
              .collection('missions')
              .where('childId', isEqualTo: user.uid)
              .where('missionTitle', isEqualTo: missionTitle)
              .where('status', isEqualTo: 'pending')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .limit(1)
              .get();

      // Konfetti & popup bara om nytt godkännande
      if (approvedSnapshot.docs.isNotEmpty) {
        final docId = approvedSnapshot.docs.first.id;
        if (prefs.getString('lastApproved_$category') != docId) {
          _confettiController.play();
          _showApprovedPopup(missionTitle);
          await prefs.setString('lastApproved_$category', docId);
        }
      }

      setState(() {
        if (category == 'battery') {
          isBatteryApproved = approvedSnapshot.docs.isNotEmpty;
          isBatteryPending = pendingSnapshot.docs.isNotEmpty;
        } else if (category == 'pant') {
          isPantApproved = approvedSnapshot.docs.isNotEmpty;
          isPantPending = pendingSnapshot.docs.isNotEmpty;
        } else if (category == 'trash') {
          isTrashApproved = approvedSnapshot.docs.isNotEmpty;
          isTrashPending = pendingSnapshot.docs.isNotEmpty;
        }
      });
    }
  }

  Future<void> _checkForNewApprovedMission(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final missionSnapshot =
        await FirebaseFirestore.instance
            .collection('missions')
            .where('childId', isEqualTo: userId)
            .where('status', isEqualTo: 'approved')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

    if (missionSnapshot.docs.isNotEmpty) {
      final docId = missionSnapshot.docs.first.id;

      if (prefs.getString('lastApprovedMission') != docId) {
        _confettiController.play();

        final missionTitle = missionSnapshot.docs.first.data()['missionTitle'];
        _showApprovedPopup(missionTitle);

        await prefs.setString('lastApprovedMission', docId);
      }
    }
  }

  void _showApprovedPopup(String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade100,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Center(
            child: Text(
              '🎉 Grattis! 🎉',
              style: TextStyle(fontSize: 24, color: Colors.green.shade800),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Uppdraget "$title" har blivit godkänt!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.green.shade700),
              ),
              SizedBox(height: 20),
              Icon(Icons.check_circle, color: Colors.green.shade800, size: 60),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
                child: Text('Okej!'),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getPlantImage() {
    if (_userScore < 50) {
      return 'assets/images/plant_stage_1.png';
    } else if (_userScore < 100) {
      return 'assets/images/plant_stage_2.png';
    } else if (_userScore < 150) {
      return 'assets/images/plant_stage_3.png';
    } else {
      return 'assets/images/plant_stage_4.png';
    }
  }

  String _getPlantStageNameByScore(int score) {
    if (score < 50) {
      return 'Frö 🌱';
    } else if (score < 100) {
      return 'Grodd 🌿';
    } else {
      return 'Träd 🌳';
    }
  }

  String _getPlantStageName() => _getPlantStageNameByScore(_userScore);

  @override
  Widget build(BuildContext context) {
    double imageSize = (100 + _userScore.toDouble()).clamp(
      100.0,
      300.0,
    ); // base size + score growth

    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD), // Matching background color
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: -3.14 / 2, // Spraya uppåt
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 10,
              gravity: 0.3,
              shouldLoop: false,
              colors: [
                Colors.green,
                Colors.lightGreen,
                Colors.yellow,
                Colors.teal,
              ],
            ),
          ),
          FutureBuilder<Map<String, String>>(
            future: fetchTodayMissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Gick ej att ladda utmaningar'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Text('Det finns inga tillgängliga utmaningar idag'),
                );
              } else {
                final missions = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.only(
                    top: 75,
                    left: 24,
                    right: 24,
                    bottom: 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                color: Colors.green.shade800,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Din poäng: $_userScore',
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
                        'Dagens utmaningar:',
                        style: TextStyle(
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isTrashApproved) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionDoneScreen(
                                            mission: missions['trash']!,
                                          ),
                                    ),
                                  );
                                } else if (isTrashPending) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionPendingScreen(
                                            mission: missions['trash']!,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => TrashScreen(
                                            mission: missions['trash']!,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(24),
                                backgroundColor:
                                  isTrashApproved || isTrashPending ? const Color.fromARGB(255, 110, 223, 97) : Colors.green,
                              ),
                              child: Icon(
                                isTrashApproved
                                    ? Icons.check
                                    : isTrashPending
                                    ? Icons.hourglass_bottom
                                    : FontAwesomeIcons.trashCan,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isPantApproved) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionDoneScreen(
                                            mission: missions['pant']!,
                                          ),
                                    ),
                                  );
                                } else if (isPantPending) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionPendingScreen(
                                            mission: missions['pant']!,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => PantScreen(
                                            mission: missions['pant']!,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(24),
                                backgroundColor:
                                  isPantApproved || isPantPending ? const Color.fromARGB(255, 110, 223, 97) : Colors.green,
                              ),
                              child: Icon(
                                isPantApproved
                                    ? Icons.check
                                    : isPantPending
                                    ? Icons.hourglass_bottom
                                    : Icons.recycling_outlined,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                if (isBatteryApproved) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionDoneScreen(
                                            mission: missions['battery']!,
                                          ),
                                    ),
                                  );
                                } else if (isBatteryPending) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => MissionPendingScreen(
                                            mission: missions['battery']!,
                                          ),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => BatteryScreen(
                                            mission: missions['battery']!,
                                          ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(24),
                                backgroundColor:
                                  isBatteryApproved || isBatteryPending ? const Color.fromARGB(255, 110, 223, 97) : Colors.green,
                              ),
                              child: Icon(
                                isBatteryApproved ? Icons.check : isBatteryPending ? Icons.hourglass_bottom : Icons.battery_charging_full,
                                size: 40,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
            },
          ),

          // Growing plant image
          Positioned(
            bottom: 70,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 500),
                    child: Image.asset(
                      _getPlantImage(),
                      key: ValueKey(_getPlantImage()),
                      height: MediaQuery.of(context).size.height * 0.3,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Level: '+
                    _getPlantStageNameByScore(_userScore),
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
        ],
      ),
      // Add the bottom navigation bar to the Scaffold
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
            label: 'Topplista',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Hem'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Inställningar',
          ),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LeaderboardScreen()),
              );
              break;
            case 1:
              // Stay on Home
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}
