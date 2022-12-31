// ignore_for_file: unused_local_variable

import 'package:chat_app/all_user.dart';
import 'package:chat_app/chatscreen.dart';
import 'package:chat_app/groupChat.dart';
import 'package:chat_app/how_to_use.dart';
import 'package:chat_app/my_profile.dart';
import 'package:chat_app/services/auth.dart';
import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/sharedPref_helper.dart';
import 'package:chat_app/signin.dart';
import 'package:cached_network_image/cached_network_image.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:jiffy/jiffy.dart';

class Home extends StatefulWidget {
  const Home({Key key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  bool isSearching = false;
  String myName, myProfilePic, myUserName, myEmail = "";
  Stream<QuerySnapshot> usersStream, chatRoomsStream;

  TextEditingController searchUsernameEditingController =
      TextEditingController();

  SelectedItem(BuildContext context, item) {
    switch (item) {
      case 0:
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AllUsers(myUserName, myProfilePic)));
        break;
      case 1:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => MyProfile()));
        break;
      case 2:
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => HowToUse()));
        break;
      case 3:
        break;
      case 4:
        AuthMethods().signOut().then((value) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => SignIn()));
        });
        break;
    }
  }

  getMyInfoFromSharedPref() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
    setState(() {});
  }

  getChatRoomIdByUsernames(String a, String b) {
    if (a.substring(0, 1).codeUnitAt(0) > b.substring(0, 1).codeUnitAt(0)) {
      return "$b\_$a";
    } else {
      return "$a\_$b";
    }
  }

  onSearchBtnClick() async {
    isSearching = true;
    setState(() {});
    usersStream = await DatabaseMethods()
        .getUserByname(searchUsernameEditingController.text, myUserName);
    setState(() {});
  }

  Widget chatRoomsList() {
    return StreamBuilder(
      stream: chatRoomsStream,
      // ignore: missing_return
      builder: (context, AsyncSnapshot<QuerySnapshot> snapShots) {
        if (snapShots.hasError) {
          return const Center(
            child: Text(
              "Error in receiving chatrooms",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        } else if (snapShots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapShots.connectionState == ConnectionState.active) {
          if (snapShots.data.docs.length == 0) {
            return const Center(
              child: Text(
                "No User Found",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
          return ListView.builder(
              itemCount: snapShots.data.docs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                QueryDocumentSnapshot s = snapShots.data.docs[index];
                Map ds = s.data();
                return ChatRoomListTile(
                    ds["lastMessage"],
                    ds["lastMessageSendTs"],
                    s.id,
                    myUserName,
                    s.id.split('_').length == 2
                        ? ds["users"][0] == myUserName
                            ? ds["displayNames"][1]
                            : ds["displayNames"][0]
                        : ds["displayName"],
                    s.id.split('_').length == 2
                        ? ds["users"][0] == myUserName
                            ? ds["profileUrls"][1]
                            : ds["profileUrls"][0]
                        : ds["profileUrl"]);
              });
        } else {
          return const Text("");
        }
      },
    );
  }

  Widget searchListUserTile({String profileUrl, name, username, email}) {
    return InkWell(
      onTap: () {
        //before going to the screen create a chatroom if not exist
        var chatRoomId = getChatRoomIdByUsernames(myUserName, username);
        Map<String, dynamic> chatRoomInfoMap = {
          "users": [myUserName, username],
          'profileUrls': [myProfilePic, profileUrl],
          'displayNames': [myName, name]
        };

        DatabaseMethods().createChatRoom(chatRoomId, chatRoomInfoMap);

        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    ChatScreen(name, profileUrl, chatRoomId)));
      },
      child: Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.all(0),
        padding: EdgeInsets.only(top: 10, bottom: 0, left: 0, right: 0),
        child: Row(
          children: [
            profileUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      profileUrl,
                      height: 50,
                      width: 50,
                    ),
                  )
                : Container(),
            const SizedBox(
              width: 12,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget searchUsersList() {
    return StreamBuilder(
      stream: usersStream,
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error in receiving chatrooms",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          );
        } else if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.data.docs.length == 0) {
            return const Center(
              child: Text(
                "No User Found",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
          return ListView.builder(
              itemCount: snapshot.data.docs.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                QueryDocumentSnapshot ds = snapshot.data.docs[index];
                return searchListUserTile(
                    profileUrl: ds["imgUrl"],
                    name: ds["name"],
                    email: ds["email"],
                    username: ds["username"]);
              });
        } else {
          return const Text("");
        }
      },
    );
  }

  getChatRooms() async {
    chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  onScreenLoading() async {
    String myUserId = await SharedPreferenceHelper().getUserId();
    Map<String, dynamic> userInfo = {"active": "1"};
    await FirebaseFirestore.instance
        .collection("users")
        .doc(myUserId)
        .update(userInfo);
    await getMyInfoFromSharedPref();
    await getChatRooms();
  }

  @override
  void initState() {
    // final fbm = FirebaseMessaging();
    // fbm.requestNotificationPermissions();
    // fbm.configure(onMessage: (msg) {
    //   print(msg);
    //   return;
    // }, onLaunch: (msg) {
    //   print(msg);
    //   return;
    // }, onResume: (msg) {
    //   print(msg);
    //   return;
    // });
    WidgetsBinding.instance.addObserver(this);

    onScreenLoading();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    String myUserId = await SharedPreferenceHelper().getUserId();
    if (state == AppLifecycleState.resumed) {
      print("resumedd");
      Map<String, dynamic> userInfo = {"active": "1"};
      await FirebaseFirestore.instance
          .collection("users")
          .doc(myUserId)
          .update(userInfo);
    } else if (state == AppLifecycleState.inactive) {
      print("inactivee");
      Map<String, dynamic> userInfo = {"active": "0"};
      await FirebaseFirestore.instance
          .collection("users")
          .doc(myUserId)
          .update(userInfo);
    } else if (state == AppLifecycleState.detached) {
      print("detacheddd");
    } else if (state == AppLifecycleState.paused) {
      print("paused");
      Map<String, dynamic> userInfo = {"active": "2"};
      await FirebaseFirestore.instance
          .collection("users")
          .doc(myUserId)
          .update(userInfo);
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Greetings"),
        actions: [
          Row(
            children: [
              myProfilePic != ""
                  ? InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyProfile()));
                      },
                      // child: ClipRRect(
                      //   borderRadius: BorderRadius.circular(40),
                      //   child: Image.network(
                      //     myProfilePic,
                      //     height: 40,
                      //     width: 40,
                      //   ),
                      // )
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: Hero(
                          tag: 'imageHero',
                          child: CachedNetworkImage(
                            imageUrl: myProfilePic,
                            height: 50,
                            placeholder: (context, myProfilePic) =>
                                const Center(
                              child: CircularProgressIndicator(),
                            ),
                            // errorWidget: (context, myProfilePic) => CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    )
                  : Container(),
              const SizedBox(
                width: 12,
              ),
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.blue),
                child: PopupMenuButton<int>(
                  itemBuilder: (context) => [
                    PopupMenuItem<int>(
                        value: 0,
                        child: Row(
                          children: const [
                            Icon(Icons.people_alt_outlined),
                            SizedBox(
                              width: 7,
                            ),
                            Text("All Users"),
                          ],
                        )),
                    PopupMenuItem<int>(
                        value: 1,
                        child: Row(
                          children: const [
                            Icon(Icons.manage_accounts),
                            SizedBox(
                              width: 7,
                            ),
                            Text("My Profile"),
                          ],
                        )),
                    PopupMenuItem<int>(
                        value: 2,
                        child: Row(
                          children: const [
                            Icon(Icons.add_to_home_screen_rounded),
                            SizedBox(
                              width: 7,
                            ),
                            Text("How to use"),
                          ],
                        )),
                    PopupMenuItem<int>(
                        value: 3,
                        child: Row(
                          children: const [
                            Icon(Icons.help),
                            SizedBox(
                              width: 7,
                            ),
                            Text("Help"),
                          ],
                        )),
                    const PopupMenuDivider(),
                    PopupMenuItem<int>(
                        value: 4,
                        child: Row(
                          children: const [
                            Icon(Icons.logout),
                            SizedBox(
                              width: 7,
                            ),
                            Text("Logout"),
                          ],
                        )),
                  ],
                  onSelected: (item) => SelectedItem(context, item),
                ),
              ),
            ],
          )
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                isSearching
                    ? InkWell(
                        onTap: () {
                          isSearching = false;
                          FocusScope.of(context).requestFocus(FocusNode());
                          searchUsernameEditingController.text = "";
                          setState(() {});
                        },
                        child: const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: Icon(Icons.arrow_back),
                        ),
                      )
                    : Container(),
                Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(vertical: 16),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey,
                            width: 1,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(
                      children: [
                        Expanded(
                            child: TextField(
                          controller: searchUsernameEditingController,
                          decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Name or Email"),
                        )),
                        InkWell(
                            onTap: () {
                              if (searchUsernameEditingController.text != "") {
                                onSearchBtnClick();
                              }
                            },
                            child: const Icon(Icons.search))
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                  child: isSearching ? searchUsersList() : chatRoomsList()),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.chat),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
              builder: (context) =>
                  GroupChat(chatRoomsStream, myUserName, myProfilePic)));
        },
      ),
    );
  }
}

class ChatRoomListTile extends StatefulWidget {
  String lastMessage;
  Timestamp lastMessageSendTs;
  String chatRoomId, myUserName, name, profileUrl;
  ChatRoomListTile(this.lastMessage, this.lastMessageSendTs, this.chatRoomId,
      this.myUserName, this.name, this.profileUrl);
  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  // String username, displayName, profileUrl = "";
  // getThisUserInfo() async {
  //   if (widget.chatRoomId.split('_').length == 2) {
  //     username = widget.chatRoomId
  //         .replaceAll(widget.myUserName, "")
  //         .replaceAll("_", "");
  //     QuerySnapshot querySnapshot =
  //         await DatabaseMethods().getUserInfo(username);
  //     displayName = "${querySnapshot.docs[0]["name"]}";
  //     profileUrl = "${querySnapshot.docs[0]["imgUrl"]}";
  //   } else {
  //     DocumentSnapshot documentSnapshot =
  //         await DatabaseMethods().getChatRoomInfo(widget.chatRoomId);
  //     displayName = "${documentSnapshot["displayName"]}";
  //     profileUrl = "${documentSnapshot["profileUrl"]}";
  //   }

  //   setState(() {});
  // }

  // @override
  // void initState() {
  //   getThisUserInfo();

  //   super.initState();
  // }

  @override
  Widget build(BuildContext context) {
    return widget.profileUrl != ""
        ? InkWell(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ChatScreen(
                          widget.name, widget.profileUrl, widget.chatRoomId)));
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: EdgeInsets.all(0),
              padding: EdgeInsets.only(top: 10, bottom: 0, left: 0, right: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Stack(
                          alignment: Alignment.bottomRight,
                          overflow: Overflow.visible,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(40),
                              child: Hero(
                                tag: 'chatImage',
                                child: Image.network(
                                  widget.profileUrl,
                                  height: 50,
                                  width: 50,
                                ),
                              ),
                            ),
                            Positioned(
                                child: Icon(
                              Icons.circle,
                              color: Colors.green,
                              size: 15,
                            ))
                          ]),
                      const SizedBox(
                        width: 12,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: Text(
                              widget.name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width * 0.43,
                            child: RichText(
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                text: TextSpan(
                                    text: widget.lastMessage,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                        fontSize: 18))),
                          ),
                        ],
                      )
                    ],
                  ),
                  Container(
                    child: widget.lastMessageSendTs
                                .toDate()
                                .add(Duration(hours: 24))
                                .compareTo(DateTime.now()) <
                            0
                        ? Text(
                            Jiffy(widget.lastMessageSendTs.toDate())
                                .format('do MMM'),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          )
                        : Text(
                            Jiffy(widget.lastMessageSendTs.toDate())
                                .format('h:mm a'),
                            style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                  )
                ],
              ),
            ),
          )
        : Container();
  }
}
