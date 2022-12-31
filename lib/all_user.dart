import 'package:chat_app/chatscreen.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AllUsers extends StatefulWidget {
  String myUserName, myProfilePic;
  AllUsers(this.myUserName, this.myProfilePic);

  @override
  _AllUsersState createState() => _AllUsersState();
}

class _AllUsersState extends State<AllUsers> {
  Stream<QuerySnapshot> all_users;

  getChatRoomIdByUsernames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  Widget allListUserTile({String profileUrl, name, username, email}) {
    return InkWell(
      onTap: () async {
        //before going to the screen create a chatroom if not exist
        var chatRoomId = getChatRoomIdByUsernames(widget.myUserName, username);
        Map<String, dynamic> chatRoomInfoMap = {
          "users": [widget.myUserName, username],
          'profileUrls': [widget.myProfilePic, profileUrl],
          'displayNames': [widget.myUserName, name]
        };

        DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);

        await Provider.of<HomeList>(context, listen: false).updateHomeList();

        Navigator.of(context).pop();
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(name, profileUrl, chatRoomId)));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: const EdgeInsets.all(0),
        padding: const EdgeInsets.all(25),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.network(
                profileUrl,
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(
              width: 12,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 3,
                ),
                Text(
                  email,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  onLaunch() async {
    all_users = await FirebaseFirestore.instance
        .collection("users")
        .where("username", isNotEqualTo: widget.myUserName)
        .snapshots();
    setState(() {});
  }

  @override
  void initState() {
    onLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Users")),
      body: StreamBuilder(
          stream: all_users,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
            return snapShot.hasData
                ? ListView.builder(
                    itemCount: snapShot.data.docs.length,
                    shrinkWrap: true,
                    itemBuilder: (context, index) {
                      DocumentSnapshot ds = snapShot.data.docs[index];
                      return allListUserTile(
                          profileUrl: ds["imgUrl"],
                          name: ds["name"],
                          email: ds["email"],
                          username: ds["username"]);
                    })
                : const Center(
                    child: CircularProgressIndicator(),
                  );
          }),
    );
  }
}
