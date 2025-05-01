import 'package:chatapp/contect.dart';
import 'package:chatapp/statusscreen.dart';
import 'package:flutter/material.dart';

class CallScreen extends StatefulWidget {
  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 0; // Default screen is Chat

    final List<Widget> _screens = [
      AllUsersScreen(),    // Chat screen as default
      StatusScreen(),      // Status screen
      CallScreen(),        // Calls screen
    ];
    void _onItemTapped(int index) {
      setState(() {
        _selectedIndex = index;
      });
    }



    return Scaffold(
      appBar: AppBar(title: Text("Calls")),
      body: Center(
        child: Text(
          "Call logs will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,

        items: [
          BottomNavigationBarItem(
            icon: InkWell(child: Icon(Icons.chat),
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (context) => AllUsersScreen()),);},),

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
