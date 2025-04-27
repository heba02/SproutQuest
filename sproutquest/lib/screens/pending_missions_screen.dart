import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';


class FullscreenImageScreen extends StatelessWidget {
  final Uint8List imageBytes; // Now using bytes instead of URL
  const FullscreenImageScreen({required this.imageBytes, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.memory(imageBytes),
        ),
      ),
    );
  }
}



class PendingMissionsScreen extends StatelessWidget {
  const PendingMissionsScreen({super.key});

  Future<Map<String, dynamic>> getCurrentUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;

        List<Map<String, dynamic>> linkedChildren = [];

        if (data.containsKey('linkedChildren') && data['linkedChildren'] is List) {
          linkedChildren = (data['linkedChildren'] as List).map<Map<String, dynamic>>((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              return {'childEmail': item.toString(), 'displayName': item.toString()};
            }
          }).toList();
        }

        return {
          'email': user.email ?? '',
          'linkedChildren': linkedChildren,
        };
      }
    }
    return {
      'email': '',
      'linkedChildren': [],
    };
  }

  Future<void> _approveMission(String missionId, String childId) async {
    final firestore = FirebaseFirestore.instance;
    final user = FirebaseAuth.instance.currentUser;
    
    // Get the current user's email (the approver)
    final currentEmail = user?.email;

    if (currentEmail != null) {
      // Update the mission status and add the adult's email to approvedBy array
      await firestore.collection('missions').doc(missionId).update({
        'status': 'approved',  // Update status to approved
        'approvedBy': FieldValue.arrayUnion([currentEmail]), // Add approver's email to approvedBy
      });

      // Fetch child’s data and update score
      final childDocRef = firestore.collection('users').doc(childId);
      final childDoc = await childDocRef.get();

      if (childDoc.exists) {
        final currentScore = (childDoc.data()?['score'] ?? 0) as int;
        await childDocRef.update({
          'score': currentScore + 10,  // Award 10 points for approval
        });
      }
    }
  }


  Future<void> _rejectMission(String missionId) async {
    final firestore = FirebaseFirestore.instance;
    await firestore.collection('missions').doc(missionId).update({
      'status': 'rejected',
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: getCurrentUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Något gick fel!'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('Ingen användardata hittades.'));
        }

        final currentEmail = snapshot.data!['email'] as String;
        final linkedChildren = List<Map<String, dynamic>>.from(snapshot.data!['linkedChildren']);

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('missions')
              .where('status', isEqualTo: 'pending')
              .where('approvers', arrayContains: currentEmail)
              .snapshots(),
          builder: (context, missionSnapshot) {
            if (missionSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (!missionSnapshot.hasData || missionSnapshot.data!.docs.isEmpty) {
              return Center(child: Text('Det finns inga uppgifter att godkänna!'));
            }

            final missions = missionSnapshot.data!.docs;

            return ListView.builder(
              itemCount: missions.length,
              itemBuilder: (context, index) {
                final mission = missions[index];
                final missionTitle = mission['missionTitle'] ?? 'No title';
                final childEmail = mission['childEmail'] ?? 'Unknown child';
                final Map<String, dynamic> missionData = mission.data() as Map<String, dynamic>;


                // Matcha barnets displayName från linkedChildren
                final child = linkedChildren.firstWhere(
                  (child) => child['childEmail'] == childEmail,
                  orElse: () => {'displayName': childEmail},
                );
                final childDisplayName = child['displayName'] ?? childEmail;

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          missionTitle,
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Text('Submitted by: $childDisplayName'),
                        if (missionData.containsKey('proofImageBase64') && missionData['proofImageBase64'] != null) ...[
                          SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => FullscreenImageScreen(imageBytes: base64Decode(missionData['proofImageBase64']),
                                  ),
                                ));
                              },
                              child: Image.memory(
                                base64Decode(missionData['proofImageBase64']),
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],

                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveMission(mission.id, mission['childId']),
                            ),
                            IconButton(
                              icon: Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectMission(mission.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

              },
            );
          },
        );
      },
    );
  }
}
