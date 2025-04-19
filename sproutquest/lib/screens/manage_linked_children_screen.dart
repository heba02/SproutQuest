import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLinkedChildrenScreen extends StatefulWidget {
  @override
  _ManageLinkedChildrenScreenState createState() => _ManageLinkedChildrenScreenState();
}

class _ManageLinkedChildrenScreenState extends State<ManageLinkedChildrenScreen> {
  List<Map<String, dynamic>> linkedChildren = [];
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    fetchLinkedChildren();
  }

  Future<void> fetchLinkedChildren() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('linkedChildren')) {
        setState(() {
          linkedChildren = List<Map<String, dynamic>>.from(doc['linkedChildren']);
          _controllers.clear(); // 🧹 Viktigt: Rensa gamla controllers
          for (var child in linkedChildren) {
            _controllers[child['childEmail']] = TextEditingController(text: child['displayName']);
          }
        });
      }
    }
  }


  Future<void> updateChildName(String childEmail, String newName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

      // 1. Uppdatera i databasen
      final updatedChildren = linkedChildren.map((child) {
        if (child['childEmail'] == childEmail) {
          return {
            'childEmail': childEmail,
            'displayName': newName,
          };
        }
        return child;
      }).toList();

      await userDocRef.update({
        'linkedChildren': updatedChildren,
      });

      // 2. Ladda om hela listan och skapa nya TextEditingControllers
      await fetchLinkedChildren();

      // 3. Visa en liten SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Child name updated!')),
      );
    }
  }


  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear(); // 🧹 Rensa minnet!
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      appBar: AppBar(
        title: Text('Manage Linked Children'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: linkedChildren.isEmpty
            ? Center(child: Text('No linked children found.'))
            : ListView.builder(
                itemCount: linkedChildren.length,
                itemBuilder: (context, index) {
                  final child = linkedChildren[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: TextFormField(
                        controller: _controllers[child['childEmail']],
                        decoration: InputDecoration(
                          labelText: 'Child Name',
                        ),
                      ),
                      subtitle: Text(child['childEmail']),
                      trailing: ElevatedButton(
                        onPressed: () {
                          final newName = _controllers[child['childEmail']]?.text.trim() ?? '';
                          if (newName.isNotEmpty) {
                            updateChildName(child['childEmail'], newName);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Save'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
} 
