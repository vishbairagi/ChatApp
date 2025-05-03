import 'package:chatapp/ChatRoom.dart';
import 'package:chatapp/callscreen.dart';
import 'package:chatapp/contect.dart';
import 'package:chatapp/statusscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class StatusScreen extends StatefulWidget {
  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int _selectedIndex = 1;
  File? _pickedFile;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> statuses = [];
  List<Map<String, dynamic>> contactsStatuses = [];

  @override
  void initState() {
    super.initState();
    _fetchStatuses();
  }

  // Fetch statuses from Firestore
  Future<void> _fetchStatuses() async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      // Fetch user's own statuses
      final userStatusesSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('statuses')
          .orderBy('time', descending: true)
          .get();

      final userStatuses = userStatusesSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id, // Add document ID
          'name': currentUser.displayName ?? 'You',
          'time': DateFormat('hh:mm a').format((data['time'] as Timestamp).toDate()),
          'type': data['type'],
          'content': data['content'],
          'viewedBy': List<String>.from(data['viewedBy'] ?? []), // Fetch viewedBy
          'isCurrentUserStatus': true, // Mark that this is the current user's status
        };
      }).toList();

      // Fetch contacts' statuses
      final contactsSnapshot = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .collection('contacts')
          .get();

      final contactStatuses = <Map<String, dynamic>>[];

      for (var contactDoc in contactsSnapshot.docs) {
        final contactStatusesSnapshot = await _firestore
            .collection('users')
            .doc(contactDoc.id)
            .collection('statuses')
            .orderBy('time', descending: true)
            .get();

        contactStatuses.addAll(contactStatusesSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'name': contactDoc['name'],
            'time': DateFormat('hh:mm a').format((data['time'] as Timestamp).toDate()),
            'type': data['type'],
            'content': data['content'],
            'viewedBy': List<String>.from(data['viewedBy'] ?? []),
            'isCurrentUserStatus': false, // Mark that this is not the current user's status
          };
        }).toList());
      }

      setState(() {
        statuses = userStatuses;
        contactsStatuses = contactStatuses;
      });
    }
  }

  // Track view count and add current user to "viewedBy" list, but exclude the poster
  Future<void> _trackView(Map<String, dynamic> status) async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      // Ensure the current user is not the one who posted the status
      if (status['id'] != null && !status['viewedBy'].contains(currentUser.uid)) {
        final statusDocRef = _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('statuses')
            .doc(status['id']); // Use document ID

        await statusDocRef.update({
          'viewedBy': FieldValue.arrayUnion([currentUser.uid])
        });

        // Update the local status with new viewers
        setState(() {
          status['viewedBy'].add(currentUser.uid);
        });
      }
    }
  }

  Widget _buildStatusItem(Map<String, dynamic> status, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Colors.grey[300],
          child: Icon(Icons.person, color: Colors.grey),
        ),
        title: Text(status['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(status['time'], style: TextStyle(color: Colors.grey, fontSize: 14)),
        trailing: status['isCurrentUserStatus'] == true
            ? Text("${status['viewedBy'].length} views", style: TextStyle(fontSize: 12, color: Colors.grey))
            : Icon(Icons.visibility, color: Colors.grey),
        onTap: () {
          _trackView(status); // Track the view when the status is tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatusDetailScreen(status: status),
            ),
          );
        },
        onLongPress: () {
          if (status['id'] != null) {
            _showDeleteDialog(status['id']);
          }
        },
      ),
    );
  }

  // Show delete confirmation dialog
  void _showDeleteDialog(String statusId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Status"),
          content: Text("Are you sure you want to delete this status?"),
          actions: [
            TextButton(
              onPressed: () async {
                final currentUser = _auth.currentUser;
                if (currentUser != null) {
                  await _firestore
                      .collection('users')
                      .doc(currentUser.uid)
                      .collection('statuses')
                      .doc(statusId)
                      .delete();
                  Navigator.pop(context); // Close the dialog
                  setState(() {
                    statuses.removeWhere((status) => status['id'] == statusId);
                  });
                }
              },
              child: Text("Delete"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickStatusMedia(ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();
    final pickedFile = await (isVideo
        ? picker.pickVideo(source: source)
        : picker.pickImage(source: source));

    if (pickedFile != null) {
      setState(() {
        _pickedFile = File(pickedFile.path);
        statuses.insert(0, {
          'name': 'You',
          'time': 'Just now',
          'type': isVideo ? 'video' : 'image',
          'content': _pickedFile!.path,
          'viewedBy': [],
          'isCurrentUserStatus': true, // Mark as current user's status
        });
      });
    }
  }

  void _addTextStatus() {
    showDialog(
      context: context,
      builder: (_) {
        String text = '';
        return AlertDialog(
          title: Text("Enter Status"),
          content: TextField(
            onChanged: (value) => text = value,
            decoration: InputDecoration(hintText: "Type your status..."),
          ),
          actions: [
            TextButton(
              onPressed: () {
                final currentUser = _auth.currentUser;
                if (currentUser != null) {
                  _firestore.collection('users').doc(currentUser.uid).collection('statuses').add({
                    'time': Timestamp.now(),
                    'type': 'text',
                    'content': text,
                    'viewedBy': [],
                  });
                  setState(() {
                    statuses.insert(0, {
                      'name': 'You',
                      'time': 'Just now',
                      'type': 'text',
                      'content': text,
                      'viewedBy': [],
                      'isCurrentUserStatus': true, // Mark as current user's status
                    });
                  });
                }
                Navigator.pop(context);
              },
              child: Text("Post"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Status"),
        actions: [
          IconButton(
            icon: Icon(Icons.camera_alt),
            onPressed: () => _pickStatusMedia(ImageSource.gallery),
            tooltip: "Add photo/video status",
          ),
        ],
        backgroundColor: Color(0xFF075E54), // WhatsApp green color
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
                  child: Icon(Icons.person, color: Colors.grey),
                ),
                title: Text(
                  "My Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Tap to add status update", style: TextStyle(color: Colors.grey)),
                onTap: _addTextStatus,
              ),
            ),
            Divider(),
            Column(
              children: statuses.asMap().map((index, status) {
                return MapEntry(index, _buildStatusItem(status, index));
              }).values.toList(),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("Recent updates", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Container(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: contactsStatuses.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> status = contactsStatuses[index];
                  return Container(
                    width: 100,
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: status['type'] == 'image'
                              ? AssetImage(status['content'])
                              : null,
                          child: status['type'] == 'text'
                              ? Icon(Icons.text_fields, size: 30)
                              : null,
                        ),
                        SizedBox(height: 8),
                        Text(
                          status['name'],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "${status['viewedBy'].length} views",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'imageStatus',
            onPressed: () => _pickStatusMedia(ImageSource.camera),
            child: Icon(Icons.camera_alt),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'videoStatus',
            onPressed: () => _pickStatusMedia(ImageSource.camera, isVideo: true),
            child: Icon(Icons.videocam),
          ),
        ],
      ),
    );
  }
}

class StatusDetailScreen extends StatelessWidget {
  final Map<String, dynamic> status;

  StatusDetailScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Status Details")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status by ${status['name']}", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Posted at: ${status['time']}"),
            SizedBox(height: 16),
            if (status['type'] == 'text') ...[
              Text(status['content'], style: TextStyle(fontSize: 16)),
            ] else if (status['type'] == 'image') ...[
              Image.file(File(status['content'])),
            ] else if (status['type'] == 'video') ...[
              // Display video (implementation might depend on package)
              Text("Video status not yet implemented"),
            ],
            SizedBox(height: 16),
            if (status['isCurrentUserStatus']) ...[
              Text("${status['viewedBy'].length} people have viewed your status."),
            ],
          ],
        ),
      ),
    );
  }
}
