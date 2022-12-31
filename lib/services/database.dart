import 'package:chat_app/services/sharedPref_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class DatabaseMethods {
  Future addUserInfoToDB(
      String userId, Map<String, dynamic> userInfoMap) async {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(userInfoMap);
  }

  Future<Stream<QuerySnapshot>> getUserByname(
      String name, String myUserName) async {
    // Stream<QuerySnapshot> displayName = FirebaseFirestore.instance
    //     .collection("users")
    //     .where("name", isEqualTo: name)
    //     .where("username", isNotEqualTo: myUserName)
    //     .snapshots();
    // Stream<QuerySnapshot> email = FirebaseFirestore.instance
    //     .collection("users")
    //     .where("name", isNotEqualTo: name)
    //     .where("email", isEqualTo: name)
    //     .where("username", isNotEqualTo: myUserName)
    //     .snapshots();
    return FirebaseFirestore.instance
        .collection("users")
        .where("name", isEqualTo: name)
        .where("username", isNotEqualTo: myUserName)
        .snapshots();
  }

  Future addMessage(
      String chatRoomId, String messageId, Map messageInfoMap) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .set(messageInfoMap);
  }

  updateLastMessageSend(String chatRoomId, Map lastMessageInfoMap) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .update(lastMessageInfoMap);
  }

  createChatRoom(String chatRoomId, Map chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapShot.exists) {
      //chatrooom already exist
      return true;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  // createChatGroup(String chatRoomId, Map groupChatRoomInfoMap) async {
  //   final snapShot = await FirebaseFirestore.instance
  //       .collection("chatrooms")
  //       .doc(chatRoomId)
  //       .get();
  // }

  Future createGroupChatRoom(String chatRoomId, Map chatRoomInfoMap) async {
    final snapShot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    if (snapShot.exists) {
      //chatrooom already exist

      return false;
    } else {
      return FirebaseFirestore.instance
          .collection("chatrooms")
          .doc(chatRoomId)
          .set(chatRoomInfoMap);
    }
  }

  Future<Stream<QuerySnapshot>> getChatRoomMessages(chatRoomId) async {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .orderBy("ts", descending: true)
        .snapshots();
  }

  Future<Stream<QuerySnapshot>> getChatRooms() async {
    String myUsername = await SharedPreferenceHelper().getUserName();
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .orderBy("lastMessageSendTs", descending: true)
        .where("users", arrayContains: myUsername)
        .snapshots();
  }

  void update(String old, String neww) async {
    String myUsername = await SharedPreferenceHelper().getUserName();
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("chatrooms")
        .where("users", arrayContains: myUsername)
        .get();
    for (var i = 0; i < snapshot.docs.length; i++) {
      print(snapshot.docs[i].id);
    }
  }

  Future<QuerySnapshot> getUserInfo(String username) async {
    return await FirebaseFirestore.instance
        .collection("users")
        .where("username", isEqualTo: username)
        .get();
  }

  Future<void> updateDisplayName(String name) async {
    String userId = await SharedPreferenceHelper().getUserId();
    Map<String, dynamic> userInfoMap = {"name": name};
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .update(userInfoMap);
  }

  Future updateImg(String myUserId, Map userInfoMap) async {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .update(userInfoMap);
  }

  Future deleteThisMessage(String chatRoomId, String messageId) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .collection("chats")
        .doc(messageId)
        .delete();
  }

  Future getChatRoomInfo(String chatRoomId) {
    return FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
  }

  Future uploadImg(PickedFile img, String myUserName) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('user_image')
        .child(myUserName + '.jpg');

    await ref.putFile(File(img.path));

    final url = await ref.getDownloadURL();
    return url;
  }

  Future<String> getGroupMembers(String chatRoomId) async {
    DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection("chatrooms")
        .doc(chatRoomId)
        .get();
    final String names = ds["users"].join(', ');
    return names;
  }
}
