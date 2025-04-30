import 'package:flutter/material.dart';

class CallScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Calls")),
      body: Center(
        child: Text(
          "Call logs will appear here.",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
