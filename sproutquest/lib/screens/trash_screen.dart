import 'dart:async';
import 'package:flutter/material.dart';
import 'home_screen.dart';

class TrashScreen extends StatefulWidget {
  final String mission;
  const TrashScreen({Key? key, required this.mission}) : super(key: key);

  @override
  _TrashScreenState createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  bool _showBubble = false;  // To control when to show the speech bubble
  String _missionTextDisplayed = ''; // Holds the mission text being typed
  String _bubbleTextDisplayed = ''; // Holds the bubble text being typed
  late Timer _typingTimer;

  final String _fullBubbleMessage = 'Klicka på kameran för att skicka en bild som bevis på att du har gjort utmaningen!'; // The speech bubble message

  @override
  void initState() {
    super.initState();

    // Start typing the mission text first
    _startTypingMissionText();
  }

  // Function to type out the mission text
  void _startTypingMissionText() {
    int index = 0;
    _typingTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (index < widget.mission.length) {
        setState(() {
          _missionTextDisplayed += widget.mission[index];
        });
        index++;
      } else {
        // Mission text finished, now show the bubble and start typing the speech bubble text
        timer.cancel();
        _startTypingBubbleText(); // Start typing the bubble text
      }
    });
  }

  // Function to type out the speech bubble text
  void _startTypingBubbleText() {
    int index = 0;
    _typingTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (index < _fullBubbleMessage.length) {
        setState(() {
          _bubbleTextDisplayed += _fullBubbleMessage[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _typingTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAD7CD),
      appBar: AppBar(
        title: const Text('Skräpuppdrag'),
        centerTitle: true,
        backgroundColor: Colors.green[700],
      ),
      body: Stack(
        children: [

          // Window background
          Positioned(
            bottom: 90,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              height: 500,
              width: MediaQuery.of(context).size.width,
              child: Image.asset('assets/images/window2.png', fit: BoxFit.fitWidth),
            ),
          ),

          // Plant image
          Positioned(
            bottom: 142,
            left: -57,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 500),
              width: 300,
              height: 300,
              child: Image.asset('assets/images/plant.png'),
            ),
          ),

          // Mission text (this is typed out first in its own box)
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Container(
              margin: EdgeInsets.all(25),
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                            minHeight: 100,
                            maxWidth: 300,
                          ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 4)),
                ],
              ),
              child: Text(
                _missionTextDisplayed, // Display mission text being typed
                style: const TextStyle(fontSize: 18, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // After mission text is completed, show the speech bubble and type out the text
          if (_missionTextDisplayed == widget.mission)
            Positioned(
              bottom: 230,
              left: 90,
              right: 10,
              child: Column(
                children: [
                  AnimatedOpacity(
                    opacity: _missionTextDisplayed == widget.mission ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeIn,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          margin: EdgeInsets.all(45),
                          padding: const EdgeInsets.all(20),
                          constraints: BoxConstraints(
                            minHeight: 145,
                            maxWidth: 300,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 8,
                                offset: Offset(2, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            _bubbleTextDisplayed, // Display bubble text being typed
                            style: const TextStyle(fontSize: 18, color: Colors.black87),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Positioned(
                          bottom: 17,
                          left: 76,
                          child: CustomPaint(
                            painter: CartoonBubbleTailPainter(),
                            size: const Size(40, 58),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Camera button
          Positioned(
            bottom: 20,
            left: MediaQuery.of(context).size.width * 0.5 - 48,
            child: ElevatedButton(
              onPressed: () => submitMissionWithPhoto(widget.mission, context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Icon(Icons.camera_alt, size: 48, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}


class CartoonBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();

    // Draw triangle pointing bottom-left
    path.moveTo(0, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Optional border outline
    final outline =
        Paint()
          ..color = const Color.fromARGB(255, 255, 255, 255)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
