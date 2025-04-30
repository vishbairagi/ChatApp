import 'dart:ui';

import 'package:chatapp/authentcation/loginpage.dart';
import 'package:chatapp/authentcation/uihelper.dart';
import 'package:chatapp/homescreen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  TextEditingController emailcontroller =TextEditingController();
  TextEditingController passwordcontroller=TextEditingController();
  FirebaseAuth _auth=FirebaseAuth.instance;

  FirebaseFirestore _firestore=FirebaseFirestore.instance;

  signUp(String email, String password) async {
    if (email == "" || password == "") {
      UiHelper.CustomAlertBox(context, "Enter Required Fields");
    } else {
      try {
        UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Get the user's UID safely
        String uid = userCredential.user?.uid ?? "";

        if (uid.isNotEmpty) {
          await _firestore.collection('users').doc(uid).set({
            "email": email,
            "status": "Unavailable",
          });

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          UiHelper.CustomAlertBox(context, "User ID is null");
        }
      } on FirebaseAuthException catch (ex) {
        UiHelper.CustomAlertBox(context, ex.code.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Up Page"),
        centerTitle: true,
      ),

      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center,
          children: [
            UiHelper.CustomTextField(emailcontroller, "Email", Icons.email, false),
            SizedBox(height: 20,),
            UiHelper.CustomTextField(passwordcontroller, "Password", Icons.password, true),
            SizedBox(height: 30,),
            UiHelper.CustomButton((){
              signUp(emailcontroller.text.toString(), passwordcontroller.text.toString());

            },"Sign Up"),


          ],
        ),
      ),

    );
  }
}
