import 'package:flutter/material.dart';
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
import 'package:confetti/confetti.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final resized = img.copyResize(originalImage, width: 300); // Resize width to 300px
    final compressed = img.encodeJpg(resized, quality: 70); // Compress to 70% quality

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

Future<void> _submitMissionWithPhoto(
  String missionTitle,
  String missionType,
  BuildContext context,
) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final firestore = FirebaseFirestore.instance;
  final missionsRef = firestore.collection('missions');
  final today = DateTime.now();
  final todayStart = DateTime(today.year, today.month, today.day);

  // Kontrollera om mission redan skickats idag
  final existingMissions = await missionsRef
      .where('childId', isEqualTo: user.uid)
      .where('missionTitle', isEqualTo: missionTitle)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
      .get();

  if (existingMissions.docs.isNotEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Du har redan gjort denna utmaning idag! ✋')),
    );
    return;
  }

  // Fråga om barnet vill lägga till bild
  bool attachImage = await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Vill du lägga till ett foto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Nej, skicka utan bild'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Ja, lägg till bild'),
          ),
        ],
      );
    },
  );

  String? base64Image;

  if (attachImage) {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      final bytes = await File(pickedFile.path).readAsBytes();
      final originalImage = img.decodeImage(bytes);
      if (originalImage != null) {
        final resized = img.copyResize(originalImage, width: 300);
        final compressed = img.encodeJpg(resized, quality: 70);
        base64Image = base64Encode(compressed);
      }
    }
  }

  // Hämta kopplade vuxna
  final userDoc = await firestore.collection('users').doc(user.uid).get();
  final List<dynamic> linkedAdultsRaw = userDoc.data()?['linkedAdults'] ?? [];

  if (linkedAdultsRaw.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inga kopplade vuxna hittades. Lägg till en först!')),
    );
    return;
  }

  List<Map<String, dynamic>> linkedAdults = linkedAdultsRaw
      .whereType<Map<String, dynamic>>()
      .where((adult) => adult['email'] != null && adult['email'].toString().isNotEmpty)
      .toList();

  List<Map<String, dynamic>> selectedAdults = [];

  // Välj vilka vuxna som ska godkänna
  await showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Välj godkännare'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Inget mission skickades.')),
    );
    return;
  }

  // Skapa mission-dokument
  final missionDoc = missionsRef.doc();

  await missionDoc.set({
    'childId': user.uid,
    'childEmail': user.email,
    'missionTitle': missionTitle,
    'missionType': missionType,
    'status': 'pending',
    'timestamp': FieldValue.serverTimestamp(),
    'approvers': selectedAdults.map((adult) => adult['email']).toList(),
    'approvedBy': [],
    if (base64Image != null) 'proofImageBase64': base64Image,
  });

  // Koppla barnet till varje vuxen om inte redan kopplat
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
            {'childEmail': user.email, 'displayName': user.email},
          ]),
        });
      }
    }
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Uppdrag skickades! 🌱')),
  );
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _userScore = 0;
  String _lastStage = '';
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _fetchUserScore();
    _confettiController = ConfettiController(duration: Duration(seconds: 2));
    _checkForApprovedMissions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final newScore = (doc.data()?['score'] ?? 0) as int;
        final newStage = _getPlantStageNameByScore(newScore);

        if (_lastStage.isNotEmpty && newStage != _lastStage) {
          _showLevelUpPopup(newStage);
        }

        setState(() {
          _userScore = newScore;
          _lastStage = newStage;
        });
      }
    }
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

  void _showLevelUpPopup(String stageName) {
    _confettiController.play();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.green.shade100,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                'Du är nu en $stageName!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, color: Colors.green.shade700),
              ),
              SizedBox(height: 20),
              Icon(Icons.eco, color: Colors.green.shade800, size: 60),
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
                child: Text('Fortsätt'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkForApprovedMissions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final prefs = await SharedPreferences.getInstance();
    final lastCheck = prefs.getString('lastApprovedMission') ?? '';

    final missionSnapshot = await FirebaseFirestore.instance
        .collection('missions')
        .where('childId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'approved')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (missionSnapshot.docs.isNotEmpty) {
      final missionId = missionSnapshot.docs.first.id;

      if (missionId != lastCheck) {
        _confettiController.play();

        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.green.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                    'Ett av dina uppdrag har blivit godkänt!',
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

        // Spara senaste mission-id efter att popup visats
        await prefs.setString('lastApprovedMission', missionId);
      }
    }
  }


  Future<String> _getMissionStatus(String missionType) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'none';

    final missionSnapshot = await FirebaseFirestore.instance
        .collection('missions')
        .where('childId', isEqualTo: user.uid)
        .where('missionType', isEqualTo: missionType)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (missionSnapshot.docs.isEmpty) {
      print ('No missions found for $missionType');
      return 'none';
    }

    print ('Mission status for $missionType: ${missionSnapshot.docs.first.data()['status']}');
    return missionSnapshot.docs.first.data()['status'] ?? 'none';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAD7CD),
      body: Stack(
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: [
              Colors.green,
              Colors.lightGreen,
              Colors.blueAccent,
              Colors.yellow,
            ],
            numberOfParticles: 30,
            maxBlastForce: 20,
            minBlastForce: 10,
            gravity: 0.3,
          ),
          FutureBuilder<Map<String, String>>(
            future: fetchTodayMissions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return const Center(child: Text('Gick ej att ladda utmaningar'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('Det finns inga tillgängliga utmaningar idag'));
              } else {
                final missions = snapshot.data!;

                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events, color: Colors.green, size: 28),
                                const SizedBox(width: 12),
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
                        Column(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 500),
                              child: Image.asset(
                                _getPlantImage(),
                                key: ValueKey(_getPlantImage()),
                                height: 200,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _getPlantStageName(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Text(
                          'Dagens utmaningar:',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const SizedBox(height: 40),
                        FutureBuilder<String>(
                          future: _getMissionStatus('battery'),
                          builder: (context, statusSnapshot) {
                            String status = statusSnapshot.data ?? 'none';
                            IconData icon;
                            Color iconColor;

                            if (status == 'pending') {
                              icon = Icons.hourglass_empty;
                              iconColor = Colors.orange;
                            } else if (status == 'approved') {
                              icon = Icons.check_circle;
                              iconColor = Colors.green;
                            } else {
                              icon = Icons.radio_button_unchecked;
                              iconColor = Colors.grey;
                            }

                            return ElevatedButton.icon(
                              onPressed: () {
                                _submitMissionWithPhoto(missions['battery']!, 'battery', context);
                              },
                              icon: Icon(icon, color: iconColor),
                              label: Text(
                                missions['battery']!,
                                textAlign: TextAlign.center,
                              ),
                              style: buttonStyle(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<String>(
                          future: _getMissionStatus('pant'),
                          builder: (context, statusSnapshot) {
                            String status = statusSnapshot.data ?? 'none';
                            IconData icon;
                            Color iconColor;

                            if (status == 'pending') {
                              icon = Icons.hourglass_empty;
                              iconColor = Colors.orange;
                            } else if (status == 'approved') {
                              icon = Icons.check_circle;
                              iconColor = Colors.green;
                            } else {
                              icon = Icons.radio_button_unchecked;
                              iconColor = Colors.grey;
                            }

                            return ElevatedButton.icon(
                              onPressed: () {
                                _submitMissionWithPhoto(missions['pant']!, 'pant', context);
                              },
                              icon: Icon(icon, color: iconColor),
                              label: Text(
                                missions['pant']!,
                                textAlign: TextAlign.center,
                              ),
                              style: buttonStyle(),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        FutureBuilder<String>(
                          future: _getMissionStatus('trash'),
                          builder: (context, statusSnapshot) {
                            String status = statusSnapshot.data ?? 'none';
                            IconData icon;
                            Color iconColor;

                            if (status == 'pending') {
                              icon = Icons.hourglass_empty;
                              iconColor = Colors.orange;
                            } else if (status == 'approved') {
                              icon = Icons.check_circle;
                              iconColor = Colors.green;
                            } else {
                              icon = Icons.radio_button_unchecked;
                              iconColor = Colors.grey;
                            }

                            return ElevatedButton.icon(
                              onPressed: () {
                                _submitMissionWithPhoto(missions['trash']!, 'trash', context);
                              },
                              icon: Icon(icon, color: iconColor),
                              label: Text(
                                missions['trash']!,
                                textAlign: TextAlign.center,
                              ),
                              style: buttonStyle(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.green.shade700,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey.shade400,
        type: BottomNavigationBarType.fixed,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add_chart),
            label: 'Topplista',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Hem',
          ),
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
                MaterialPageRoute(builder: (context) => const LeaderboardScreen()),
              );
              break;
            case 1:
              // Already on Home
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
              break;
          }
        },
      ),
    );
  }
}