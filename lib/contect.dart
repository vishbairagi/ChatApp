import 'package:chatapp/ChatRoom.dart';
import 'package:chatapp/callscreen.dart';
import 'package:chatapp/statusscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AllUsersScreen extends StatefulWidget {
  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSearching = false;
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff075E54),
        title: _isSearching
            ? TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white),
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        )
            : const Text(
          "Chats",
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 35),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                _searchQuery = '';
              });
            },
          ),
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                });
              },
            ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs.where(
                (doc) => doc.id != currentUser!.uid,
          );

          final filteredUsers = _searchQuery.isEmpty
              ? users
              : users.where((doc) {
            final userName = doc['name'].toLowerCase();
            return userName.contains(_searchQuery.toLowerCase());
          }).toList();

          return ListView(
            children: filteredUsers.map((doc) {
              final userData = doc.data() as Map<String, dynamic>;
              final chatRoomId = _getChatRoomId(
                (currentUser?.displayName ?? currentUser?.email ?? ''),
                userData['name'],
              );

              return StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('chatroom')
                    .doc(chatRoomId)
                    .collection('chats')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, chatSnapshot) {
                  String lastMessage = 'No messages yet';
                  String lastTime = '';
                  int unreadCount = 0;
                  Icon? statusIcon;

                  if (chatSnapshot.hasData && chatSnapshot.data!.docs.isNotEmpty) {
                    final lastMessageData = chatSnapshot.data!.docs.first.data() as Map<String, dynamic>;
                    lastMessage = lastMessageData['message'] ?? '';
                    final time = (lastMessageData['time'] as Timestamp).toDate();
                    lastTime = DateFormat('hh:mm a').format(time);

                    final status = lastMessageData['status'] ?? 'sent';
                    if (status == 'sending') {
                      statusIcon = const Icon(Icons.access_time, size: 16, color: Colors.grey);
                    } else if (status == 'sent') {
                      statusIcon = const Icon(Icons.check, size: 16, color: Colors.grey);
                    } else if (status == 'delivered') {
                      statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.blue);
                    } else if (status == 'read') {
                      statusIcon = const Icon(Icons.done_all, size: 16, color: Colors.green);
                    }

                    // Count unread messages not sent by current user
                    unreadCount = chatSnapshot.data!.docs
                        .where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['read'] == false && data['sender'] != currentUser!.uid;
                    })
                        .length;
                  }

                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(userData['name']),
                    subtitle: Text(lastMessage),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (lastTime.isNotEmpty) Text(lastTime, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (statusIcon != null) statusIcon,
                            if (unreadCount > 0)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.green,
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatRoom(
                            chatRoomId: chatRoomId,
                            userMap: userData,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StatusScreen()));
          } else if (index == 2) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => CallScreen()));
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chats'),
          BottomNavigationBarItem(icon: Icon(Icons.star), label: 'Status'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
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
