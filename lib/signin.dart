// ignore_for_file: prefer_const_constructors

import 'package:chat_app/services/auth.dart';
import 'package:flutter/material.dart';

class SignIn extends StatefulWidget {
  // const SignIn({Key? key}) : super(key: key);

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: InkWell(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Color(0xffDB4437),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "Sign in with Google",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          onTap: () {
            AuthMethods().signInWithGoogle(context);
          },
        ),
      ),
    );
  }
}
