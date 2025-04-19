import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageLinkedAdultsScreen extends StatefulWidget {
  @override
  _ManageLinkedAdultsScreenState createState() => _ManageLinkedAdultsScreenState();
}

class _ManageLinkedAdultsScreenState extends State<ManageLinkedAdultsScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> linkedAdults = [];

  @override
  void initState() {
    super.initState();
    fetchLinkedAdults();
  }

  Future<void> fetchLinkedAdults() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()!.containsKey('linkedAdults')) {
        setState(() {
          linkedAdults = List<Map<String, dynamic>>.from(doc['linkedAdults']);
        });
      }
    }
  }

  Future<void> addLinkedAdult() async {
    final email = _emailController.text.trim();
    final name = _nameController.text.trim();
    
    if (email.isEmpty || name.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.update({
        'linkedAdults': FieldValue.arrayUnion([
          {
            'name': name,
            'email': email,
          }
        ]),
      });
      _emailController.clear();
      _nameController.clear();
      fetchLinkedAdults();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFDAD7CD),
      appBar: AppBar(
        title: Text('Manage Linked Adults'),
        backgroundColor: Colors.green.shade700, 
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Connected Adults:',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: linkedAdults.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('${linkedAdults[index]['name']} (${linkedAdults[index]['email']})'),
                  );
                },
              ),
            ),
            Divider(height: 40),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Enter adult\'s name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Enter adult\'s email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: addLinkedAdult,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Add adult'),
            ),
          ],
        ),
      ),
    );
  }
}