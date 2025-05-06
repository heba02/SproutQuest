import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'dart:convert';

class MissionDoneScreen extends StatelessWidget {
  final String mission;
  const MissionDoneScreen({Key? key, required this.mission}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFDAD7CD),
      appBar: AppBar(
        backgroundColor: Colors.green[700],
      ),
      body: Stack(  // Wrap everything in a Stack
        children: [
          
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child:
            Text('Du har redan gjort \n denna utmaning!',
              style: const TextStyle(
                fontSize: 28,
                color: Color.fromARGB(221, 9, 47, 5),
              ),
              textAlign: TextAlign.center,
            ),
          ),     
          
         
          Positioned(
            top: 150,
            child:
            Text(
              mission,
              style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          
          ),     
          
          
          Positioned(
            bottom: 20, 
            left: MediaQuery.of(context).size.width * 0.5 - 48,  
            child: 
            Text('Fota och skicka in'),
          ),
        ],
      ),
    );
  }
}