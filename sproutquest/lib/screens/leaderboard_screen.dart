import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD), // Matching background color
      appBar: AppBar(
        title: Text(
          'Leaderboard',
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
          size: 35, // Bigger back arrow
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Top Players",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream:
                    FirebaseFirestore.instance
                        .collection('users')
                        .orderBy('score', descending: true)
                        .limit(6)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final leaderboard = snapshot.data!.docs;

                  if (leaderboard.isEmpty) {
                    return const Center(child: Text("No players yet"));
                  }

                  return ListView.separated(
                    itemBuilder: (context, index) {
                      final player =
                          leaderboard[index].data() as Map<String, dynamic>;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade700,
                          child: Text(
                            '#${index + 1}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          player['email'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                          ),
                        ),
                        trailing: Text(
                          "${player['score'] ?? 0} pts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ); //TODO
                    },
                    separatorBuilder:
                        (context, index) => Divider(
                          color: Colors.grey.shade400,
                          thickness: 0.8,
                          indent: 20,
                          endIndent: 20,
                        ),
                    itemCount: leaderboard.length,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
