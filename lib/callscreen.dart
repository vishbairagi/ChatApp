import 'package:chatapp/contect.dart';
import 'package:chatapp/statusscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late User _currentUser;
  String _name = '';
  String _email = '';
  String _profileUrl = '';
  bool _isEditing = false;
  bool _isLoading = true;

  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(_currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? 'Unknown';
          _email = userDoc['email'] ?? 'No Email';
          _profileUrl = userDoc['profileUrl'] ?? '';
          _nameController.text = _name;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveName() async {
    String updatedName = _nameController.text.trim();

    if (updatedName.isNotEmpty && updatedName != _name) {
      try {
        await _firestore.collection('users').doc(_currentUser.uid).update({
          'name': updatedName,
        });

        setState(() {
          _name = updatedName;
          _isEditing = false;
        });
      } catch (e) {
        print("Error saving name: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to save name.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text("Profile")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Picture
            Center(
              child: _profileUrl.isEmpty
                  ? CircleAvatar(

                radius: 60,
                backgroundColor: Colors.black,
                child: Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.white,
                ),
              )
                  : CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_profileUrl),
              ),
            ),
            SizedBox(height: 30),

            // Name (editable)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: _isEditing
                  ? TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) {
                  _saveName();
                },
              )
                  : Text(
                _name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Email
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
            SizedBox(height: 20),

            // Static Status
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        items: [
          BottomNavigationBarItem(
            icon: InkWell(
              child: Icon(Icons.chat),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AllUsersScreen()),
                );
              },
            ),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              child: Icon(Icons.star),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StatusScreen()),
                );
              },
            ),
            label: 'Status',
          ),
          BottomNavigationBarItem(
            icon: InkWell(
              child: Icon(Icons.person),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => CallScreen()),
                );
              },
            ),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black54,
      ),
    );
  }
}