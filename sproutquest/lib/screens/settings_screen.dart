import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Center(
        child: Text('Settings Screen Placeholder'),
      ),
    );
  }
}
