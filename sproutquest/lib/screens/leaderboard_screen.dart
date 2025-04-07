import 'package:flutter/material.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboardData = [
    {"rank": 1, "name": "Player1", "score": 1500},
    {"rank": 2, "name": "Player2", "score": 1400},
    {"rank": 3, "name": "Player3", "score": 1350},
    {"rank": 4, "name": "Player4", "score": 1300},
    {"rank": 5, "name": "Player5", "score": 1250},
  ];

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
              child: ListView.separated(
                itemCount: leaderboardData.length,
                separatorBuilder: (context, index) => Divider(
                  color: Colors.grey.shade400,
                  thickness: 0.8,
                  indent: 20,
                  endIndent: 20,
                ),
                itemBuilder: (context, index) {
                  final player = leaderboardData[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green.shade700,
                      child: Text(
                        player["rank"].toString(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    title: Text(
                      player["name"],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                    trailing: Text(
                      "${player["score"]} pts",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
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

