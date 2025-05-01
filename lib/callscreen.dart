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
  String _name = '';  // Initialize with empty string
  String _email = ''; // Initialize with empty string
  String _profileUrl = ''; // Initialize with empty string
  TextEditingController _nameController = TextEditingController();  // Controller for the name field
  bool _isEditing = false; // Flag to track if the name is being edited

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _fetchUserProfile();
  }

  // Fetch user data from Firestore
  Future<void> _fetchUserProfile() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(_currentUser.uid).get();
      if (userDoc.exists) {
        setState(() {
          _name = userDoc['name'] ?? 'Unknown';
          _email = userDoc['email'] ?? 'No Email';
          _profileUrl = userDoc['profileUrl'] ?? '';
          _nameController.text = _name;  // Set the name controller text to the fetched name
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  // Function to save the updated name to Firestore
  Future<void> _saveName() async {
    String updatedName = _nameController.text.trim();

    if (updatedName.isNotEmpty && updatedName != _name) {
      try {
        // Update name in Firestore
        await _firestore.collection('users').doc(_currentUser.uid).update({
          'name': updatedName,
        });

        // Update the local name and return to non-editable mode
        setState(() {
          _name = updatedName;
          _isEditing = false; // Switch to non-editable mode
        });
      } catch (e) {
        print("Error saving name: $e");
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Failed to save name."),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner if name or email is empty (data hasn't been fetched yet)
    if (_name.isEmpty || _email.isEmpty) {
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
              child: CircleAvatar(
                radius: 60,
                backgroundImage: _profileUrl.isEmpty
                    ? AssetImage('assets/default_profile.png') as ImageProvider
                    : NetworkImage(_profileUrl),
              ),
            ),
            SizedBox(height: 20),

            // Name (editable)
            GestureDetector(
              onTap: () {
                // Make the name field editable
                setState(() {
                  _isEditing = true; // Switch to editing mode when the name is tapped
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
                  // Save the updated name when the user presses "Enter"
                  _saveName();
                },
              )
                  : Text(
                _name,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ),
            SizedBox(height: 10),

            // Email
            Text(
              _email,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 20),

            // Status (Optional)
            Text(
              'Status: Unavailable',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0, // Set the default screen to 'Home'
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => CallScreen()),
                );
              },
            ),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
      ),
    );
  }
}
