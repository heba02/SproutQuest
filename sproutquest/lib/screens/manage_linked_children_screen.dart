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
        final rawChildren = List<Map<String, dynamic>>.from(doc['linkedChildren']);
        final List<Map<String, dynamic>> enrichedChildren = [];

        for (var child in rawChildren) {
          final email = child['childEmail'];
          final displayName = child['displayName'] ?? email;

          final childQuery = await FirebaseFirestore.instance
              .collection('users')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

          int score = 0;
          if (childQuery.docs.isNotEmpty) {
            score = childQuery.docs.first.data()['score'] ?? 0;
          }

          enrichedChildren.add({
            'childEmail': email,
            'displayName': displayName,
            'score': score,
          });
        }

        setState(() {
          linkedChildren = enrichedChildren;
          _controllers.clear();
          for (var child in enrichedChildren) {
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

      await fetchLinkedChildren();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barnets namn uppdaterat!')),
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      appBar: AppBar(
        title: Text('Hantera länkade barn'),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: linkedChildren.isEmpty
            ? Center(child: Text('Inga länkade barn hittades.'))
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
                          labelText: 'Barnets namn',
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(child['childEmail']),
                          SizedBox(height: 4),
                          Text(
                            'Poäng: ${child['score']}',
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ],
                      ),
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
                        child: Text('Spara'),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}