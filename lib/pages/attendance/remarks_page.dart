import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RemarksScreen extends StatefulWidget {
  final String docId; // ID dokumen presensi
  RemarksScreen({required this.docId});

  @override
  _RemarksScreenState createState() => _RemarksScreenState();
}

class _RemarksScreenState extends State<RemarksScreen> {
  final TextEditingController remarksController = TextEditingController();
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadRemarks();
  }

  void _loadRemarks() async {
    String uid = auth.currentUser!.uid;
    DocumentSnapshot doc = await firestore
        .collection('users')
        .doc(uid)
        .collection('presensi')
        .doc(widget.docId)
        .get();

    if (doc.exists) {
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      setState(() {
        remarksController.text = data?['masuk']['remarks'] ?? '';
      });
    }
  }

  void _updateRemarks() async {
    String uid = auth.currentUser!.uid;
    await firestore
        .collection('users')
        .doc(uid)
        .collection('presensi')
        .doc(widget.docId)
        .update({
      "masuk.remarks": remarksController.text, // Update remarks
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Remarks updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Remarks')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Remarks:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: remarksController,
              decoration: InputDecoration(
                hintText: "Enter remarks...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _updateRemarks,
              child: Text("Save"),
            ),
          ],
        ),
      ),
    );
  }
}
