import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';

class MissionDoneScreen extends StatefulWidget {
  final String mission;
  const MissionDoneScreen({Key? key, required this.mission}) : super(key: key);

  @override
  _MissionDoneScreenState createState() => _MissionDoneScreenState();
}

class _MissionDoneScreenState extends State<MissionDoneScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAD7CD),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
        title: Text('Uppdrag slutfört'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2, // downward
              maxBlastForce: 10,
              minBlastForce: 4,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.3,
              shouldLoop: false,
              colors: const [Color.fromARGB(255, 98, 238, 102), Color.fromARGB(255, 246, 44, 132), Colors.yellow, Color.fromARGB(255, 88, 167, 231)],
            ),
          ),

          // Content
          Column(
            children: [
              const SizedBox(height: 40),

              // Mission box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.mission,
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Completion message
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Du har redan gjort\ndenna utmaning!',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Color.fromARGB(221, 9, 47, 5),
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 40),

              const Icon(Icons.check_circle_outline_outlined, size: 68, color: Colors.green),
            ],
          ),
        ],
      ),
    );
  }
}
