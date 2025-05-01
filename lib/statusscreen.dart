import 'package:chatapp/callscreen.dart';
import 'package:chatapp/contect.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class StatusScreen extends StatefulWidget {
  @override
  _StatusScreenState createState() => _StatusScreenState();
}

class _StatusScreenState extends State<StatusScreen> {
  int _selectedIndex = 1;
  File? _pickedFile;

  final List<Map<String, dynamic>> statuses = [
    {'name': 'Alice', 'time': 'Today, 10:00 AM', 'type': 'text', 'content': 'Feeling great! 😎'},
    {'name': 'Bob', 'time': 'Today, 9:30 AM', 'type': 'image', 'content': 'assets/sample.jpg'},
    // Add more fake statuses here
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navigation
    if (index == 0) {
      Navigator.pushNamed(context, '/chat');
    } else if (index == 2) {
      Navigator.pushNamed(context, '/calls');
    }
  }

  Future<void> _pickStatusMedia(ImageSource source, {bool isVideo = false}) async {
    final picker = ImagePicker();
    final pickedFile = await (isVideo
        ? picker.pickVideo(source: source)
        : picker.pickImage(source: source));

    if (pickedFile != null) {
      setState(() {
        _pickedFile = File(pickedFile.path);
        // Here you can upload the file and update backend
      });
    }
  }

  void _addTextStatus() {
    // Implement your logic or navigate to a new screen to enter text
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
                setState(() {
                  statuses.insert(0, {
                    'name': 'You',
                    'time': 'Just now',
                    'type': 'text',
                    'content': text
                  });
                });
                Navigator.pop(context);
              },
              child: Text("Post"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusItem(Map<String, dynamic> status) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: status['type'] == 'image'
            ? AssetImage(status['content'])
            : null,
        child: status['type'] == 'text' ? Icon(Icons.text_fields) : null,
      ),
      title: Text(status['name']),
      subtitle: Text(status['time']),
      onTap: () {
        // Open status detail (image/video/text view)
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Status")),
      body: ListView(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.person),
            ),
            title: Text("My Status"),
            subtitle: Text("Tap to add status update"),
            onTap: _addTextStatus,
          ),
          Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text("Recent updates", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ...statuses.map(_buildStatusItem).toList(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "textStatus",
            mini: true,
            child: Icon(Icons.edit),
            onPressed: _addTextStatus,
            tooltip: "Add text status",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "photoStatus",
            child: Icon(Icons.camera_alt),
            onPressed: () => _pickStatusMedia(ImageSource.gallery),
            tooltip: "Add photo/video status",
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AllUsersScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen()));
          }
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.circle), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.call), label: 'Calls'),
        ],
      ),
    );
  }
}