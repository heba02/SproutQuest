import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    await firestore.collection('missions').doc(missionId).update({
      'status': 'approved',
    });

    final childDocRef = firestore.collection('users').doc(childId);
    final childDoc = await childDocRef.get();

    if (childDoc.exists) {
      final currentScore = (childDoc.data()?['score'] ?? 0) as int;
      await childDocRef.update({
        'score': currentScore + 10,
      });
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
          return Center(child: Text('Something went wrong!'));
        }
        if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No user data found.'));
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
              return Center(child: Text('No missions to approve!'));
            }

            final missions = missionSnapshot.data!.docs;

            return ListView.builder(
              itemCount: missions.length,
              itemBuilder: (context, index) {
                final mission = missions[index];
                final missionTitle = mission['missionTitle'] ?? 'No title';
                final childEmail = mission['childEmail'] ?? 'Unknown child';

                // 🔥 Matcha barnets displayName från linkedChildren
                final child = linkedChildren.firstWhere(
                  (child) => child['childEmail'] == childEmail,
                  orElse: () => {'displayName': childEmail},
                );
                final childDisplayName = child['displayName'] ?? childEmail;

                return Card(
                  margin: EdgeInsets.all(12),
                  child: ListTile(
                    title: Text(missionTitle),
                    subtitle: Text('Submitted by: $childDisplayName'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
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
