import 'package:flutter/material.dart';
import 'home_screen.dart';

class TrashScreen extends StatelessWidget {
  final String mission;
  const TrashScreen({Key? key, required this.mission}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trash Mission'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              mission,
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                submitMissionWithPhoto(mission, context); 
              },
              child: Text('Submit Mission Photo 📷'),
            ),
          ],
        ),
      ),
    );
  }
}