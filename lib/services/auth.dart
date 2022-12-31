import 'package:chat_app/home.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/sharedPref_helper.dart';
import 'package:chat_app/signin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthMethods {
  final FirebaseAuth auth = FirebaseAuth.instance;

  getCurrentUser() async {
    return await auth.currentUser;
  }

  signInWithGoogle(BuildContext context) async {
    final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
    final GoogleSignIn _googleSignIn = GoogleSignIn();

    final GoogleSignInAccount googleSignInAccount =
        await _googleSignIn.signIn();

    final GoogleSignInAuthentication googleSignInAuthentication =
        await googleSignInAccount.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleSignInAuthentication.idToken,
        accessToken: googleSignInAuthentication.accessToken);

    UserCredential result =
        await _firebaseAuth.signInWithCredential(credential);

    User userDetails = result.user;

    if (result != null) {
      print("Auth is here");
      await SharedPreferenceHelper().saveUserEmail(userDetails.email);
      await SharedPreferenceHelper().saveUserId(userDetails.uid);
      await SharedPreferenceHelper()
          .saveUserName(userDetails.email.replaceAll("@gmail.com", ""));
      await SharedPreferenceHelper().saveDisplayName(userDetails.displayName);
      await SharedPreferenceHelper().saveUserProfileUrl(userDetails.photoURL);
      await SharedPreferenceHelper().savePhoneNumber(userDetails.phoneNumber);
      print(userDetails.phoneNumber);

      Map<String, dynamic> userInfoMap = {
        "email": userDetails.email,
        "username": userDetails.email.replaceAll("@gmail.com", ""),
        "name": userDetails.displayName,
        "imgUrl": userDetails.photoURL,
        "phone": userDetails.phoneNumber,
        "active": "1"
      };

      DatabaseMethods()
          .addUserInfoToDB(userDetails.uid, userInfoMap)
          .then((value) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Home()));
      });
    }
  }

  Future signOut() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.clear();
    await auth.signOut();
  }
}
