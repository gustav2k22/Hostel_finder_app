import 'package:flutter/material.dart';
import 'package:hostel_app/EditHostelDetails.dart';
import 'package:hostel_app/HostelDetailsForm.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UploadHostels extends StatefulWidget {
  @override
  _UploadHostelsState createState() => _UploadHostelsState();
}

class _UploadHostelsState extends State<UploadHostels> {
  List<String> hostelNames = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Fetch hostel names
    fetchHostelNames();
  }

  Future<void> fetchHostelNames() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        QuerySnapshot querySnapshot =
        await _firestore.collection('hostels').get();

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            hostelNames = querySnapshot.docs
                .map((doc) => doc['name'].toString())
                .toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching hostel names: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hostel List'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Display multiple hostel names
              if (hostelNames.isNotEmpty)
                Column(
                  children: hostelNames.map((name) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditHostelDetailsForm(),
                          ),
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Text(
                          name,
                          style: TextStyle(fontSize: 18.0),
                        ),
                      ),
                    );
                  }).toList(),
                ),

              // Add new hostel button
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Handle adding mode
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HostelDetailsForm(),
                    ),
                  );
                },
                child: Text('Add New Hostel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
