import 'package:chatapp/ChatRoom.dart';
import 'package:chatapp/callscreen.dart';
import 'package:chatapp/contect.dart';
import 'package:chatapp/statusscreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {


  int _selectedIndex = 0; // Default screen is Chat

  final List<Widget> _screens = [
    HomeScreen(),    // Chat screen as default
    StatusScreen(),      // Status screen
    CallScreen(),        // Calls screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }




  Map<String, dynamic>? userMap;
  bool isLoading = false;
  bool isSearching = false;

  final TextEditingController _search = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    setStatus("Online");
  }

  void setStatus(String status) async {
    await _firestore.collection('users').doc(_auth.currentUser!.uid).update({
      "status": status,
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setStatus("Online");
    } else {
      setStatus("Offline");
    }
  }

  String chatRoomId(String user1, String user2) {
    if (user1[0].toLowerCase().codeUnits[0] > user2.toLowerCase().codeUnits[0]) {
      return "$user1$user2";
    } else {
      return "$user2$user1";
    }
  }

  void onSearch() async {
    if (_search.text.trim().isEmpty) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await _firestore
          .collection('users')
          .where("email", isEqualTo: _search.text.trim())
          .get();

      if (result.docs.isNotEmpty) {
        setState(() {
          userMap = result.docs.first.data();
        });
      } else {
        setState(() {
          userMap = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found")),
        );
      }
    } catch (e) {
      print("Search error: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text("ChatApp"),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                _search.clear();
                userMap = null;
              });
            },
          ),
        ],
      ),
      body:
      isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
          children: [
            if (isSearching) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: "Search by email...",
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: onSearch,
                      style: ElevatedButton.styleFrom(
                        shape: CircleBorder(),
                        padding: EdgeInsets.all(12),
                      ),
                      child: Icon(Icons.search),
                    ),
                  ],
                ),
              ),
            ],
            if (userMap != null)
              ListTile(
                onTap: () {
                  final currentUser = _auth.currentUser;
                  if (currentUser != null && currentUser.displayName != null) {
                    final roomId = chatRoomId(
                      currentUser.displayName!,
                      userMap!['email'],
                    );

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoom(
                          chatRoomId: roomId,
                          userMap: userMap!,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Your display name is not set")),
                    );
                  }
                },
                leading: CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  userMap!['name'],
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(userMap!['email']),
                trailing: Icon(Icons.chat),
              )
          ]            ),





      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.message),
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => AllUsersScreen()),
          );
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: InkWell(child: Icon(Icons.star),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => StatusScreen()),);},),
            label: 'Status',),
          BottomNavigationBarItem(
            icon: InkWell(child: Icon(Icons.call),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) =>CallScreen()));

              },
            ),

            label: 'Call',
          ),
          /* BottomNavigationBarItem(
            icon: InkWell(child: Icon(Icons.view_comfortable),
              onTap: (){
                Navigator.push(context, MaterialPageRoute(builder: (context) => ResultPage(isLoggedIn: true,isAdmin: isAdmin)),);

              },

            ),
            label: 'Result',
          ),*/
        ],
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
      ),





    );
  }
}
