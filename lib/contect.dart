import 'package:chatapp/ChatRoom.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AllUsersScreen extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Contact"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where(
                (doc) => doc.id != currentUser!.uid,
          );

          return ListView(
            children: users.map((doc) {
              final userData = doc.data() as Map<String, dynamic>;

              return ListTile(
                leading: CircleAvatar(child: Icon(Icons.person)),
                title: Text(userData['name']),
                subtitle: Text(userData['email']),
                onTap: () {
                  final roomId = _getChatRoomId(
                    currentUser!.displayName ?? currentUser.email!,
                    userData['name'],
                  );

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatRoom(
                        chatRoomId: roomId,
                        userMap: userData,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _getChatRoomId(String user1, String user2) {
    if (user1.toLowerCase().compareTo(user2.toLowerCase()) > 0) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }
}
