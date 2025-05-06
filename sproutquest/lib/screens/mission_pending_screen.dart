import 'package:flutter/material.dart';

class MissionPendingScreen extends StatefulWidget {
  final String mission;
  const MissionPendingScreen({Key? key, required this.mission}) : super(key: key);

  @override
  _MissionPendingScreenState createState() => _MissionPendingScreenState();
}

class _MissionPendingScreenState extends State<MissionPendingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(); // Loops the animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Uppdrag skickat!"),
        backgroundColor: Colors.green[700],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _controller,
              child: Icon(
                Icons.hourglass_top,
                size: 80,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Ditt uppdrag har skickats och väntar på godkännande!",
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
