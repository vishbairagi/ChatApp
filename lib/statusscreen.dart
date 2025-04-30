import 'package:flutter/material.dart';

class StatusScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Status")),
      body: Center(
        child: Text(
          "Status feature coming soon!",
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
