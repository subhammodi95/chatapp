// ignore_for_file: file_names

import 'dart:io';

import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

List<String> groupList = [];
List<String> groupListImg = [];

class GroupChat extends StatefulWidget {
  Stream<QuerySnapshot> chatRoomsStream;
  String myUserName, myProfilePic;
  GroupChat(this.chatRoomsStream, this.myUserName, this.myProfilePic);

  @override
  _GroupChatState createState() => _GroupChatState();
}

class _GroupChatState extends State<GroupChat> {
  TextEditingController groupName = TextEditingController();
  FocusNode myfocusNode;
  PickedFile pickImageFile;
  File image;

  void _pickImage() async {
    pickImageFile = await ImagePicker()
        .getImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 250);
    if (pickImageFile != null) {
      image = File(pickImageFile.path);
    }
    setState(() {
      // FocusScope.of(context).requestFocus(FocusNode());
      // myfocusNode.requestFocus();
    });
  }

  createGroup(List groupList) {
    Map<String, dynamic> chatRoomInfoMap = {
      "users": groupList,
    };

    showModalBottomSheet(
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
        top: Radius.circular(25.0),
      )),
      isScrollControlled: true,
      context: context,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  color: Colors.grey.withOpacity(0.4),
                ),
              ),
              const SizedBox(
                height: 30,
              ),
              const Text(
                "New Group",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          child: image != null
                              ? CircleAvatar(
                                  radius: 30,
                                  backgroundImage: FileImage(image),
                                )
                              : const Icon(Icons.image),
                          onTap: () {
                            _pickImage();
                          },
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: groupName,
                              focusNode: myfocusNode,
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                labelText: 'Name',
                                labelStyle: TextStyle(
                                  fontSize: 20,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: const Icon(Icons.person),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Consumer<updateRowList>(
                      builder: (ctx, provider, _) => Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Participants: ${groupList.length}",
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic),
                            ),
                            SingleChildScrollView(
                              physics: const BouncingScrollPhysics(
                                  parent: AlwaysScrollableScrollPhysics()),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    List.generate(groupListImg.length, (index) {
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(40),
                                              child: Image.network(
                                                groupListImg[index],
                                                height: 50,
                                                width: 50,
                                              )),
                                          groupList[index] != widget.myUserName
                                              ? Positioned(
                                                  child: GestureDetector(
                                                  child: const Icon(
                                                    Icons.remove_circle,
                                                    color: Colors.red,
                                                  ),
                                                  onTap: () async {
                                                    // if (groupList.length > 3) {
                                                    groupListImg
                                                        .removeAt(index);
                                                    groupList.removeAt(index);
                                                    await Provider.of<
                                                                updateRowList>(
                                                            context,
                                                            listen: false)
                                                        .updateList();
                                                    setState(() {});
                                                    // }
                                                  },
                                                ))
                                              : Container()
                                        ]),
                                  );
                                }),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    MaterialButton(
                      onPressed: () async {
                        if (groupList.length < 3) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                              "Group should have atleast 3 members",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (groupName.text.contains('_')) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                            content: Text(
                              "Group name should not contain underscores",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            backgroundColor: Colors.red,
                          ));
                          return;
                        }
                        if (groupName.text.isNotEmpty &&
                            groupList.length > 2 &&
                            pickImageFile != null) {
                          DatabaseMethods()
                              .createGroupChatRoom(
                                  "group\_${widget.myUserName}\_${groupName.text}",
                                  chatRoomInfoMap)
                              .then((value) async {
                            if (value == false) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                content: Text(
                                  "Group with same name already exist",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                backgroundColor: Colors.red,
                              ));
                            } else {
                              await DatabaseMethods()
                                  .uploadImg(pickImageFile,
                                      "group\_${widget.myUserName}\_${groupName.text}")
                                  .then((imgUrl) {
                                Map<String, dynamic> lastMessageInfoMap = {
                                  "lastMessage": "Welcome Everyone",
                                  "lastMessageId": "",
                                  "profileUrl": imgUrl,
                                  "displayName": groupName.text,
                                  "lastMessageSendTs": DateTime.now(),
                                  "lastMessageSendBy": widget.myUserName
                                };
                                image = null;
                                pickImageFile = null;
                                DatabaseMethods().updateLastMessageSend(
                                    "group\_${widget.myUserName}\_${groupName.text}",
                                    lastMessageInfoMap);
                                setState(() {});
                              });

                              Navigator.of(context).pop();
                              groupList.clear();
                              groupList.add(widget.myUserName);
                              groupListImg.clear();
                              groupListImg.add(widget.myProfilePic);
                              setState(() {});
                            }
                          });
                        }
                      },
                      color: Theme.of(context).primaryColor,
                      elevation: 0,
                      highlightColor: Colors.red.withOpacity(0.3),
                      highlightElevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        width: double.infinity,
                        child: const Center(
                          child: Text(
                            "Create",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 30,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget chatRoomsList() {
    return StreamBuilder(
        stream: widget.chatRoomsStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapShots) {
          return snapShots.hasData
              ? ListView.builder(
                  itemCount: snapShots.data.docs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapShots.data.docs[index];
                    return ds.id.toString().split('_').length == 2
                        ? ChatRoomListTile(
                            ds["lastMessageSendTs"], ds.id, widget.myUserName)
                        : Container();
                  })
              : const Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  getChatRooms() async {
    widget.chatRoomsStream = await DatabaseMethods().getChatRooms();
    setState(() {});
  }

  onLoading() async {
    myfocusNode = FocusNode();
    groupList.clear();
    groupListImg.clear();
    groupList.add(widget.myUserName);
    groupListImg.add(widget.myProfilePic);
    getChatRooms();
    // }
  }

  @override
  void initState() {
    onLoading();
    super.initState();
  }

  @override
  void dispose() {
    myfocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Create Group"),
        ),
        body: Container(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            child: chatRoomsList(),
          ),
        ),
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.ac_unit_rounded),
            onPressed: () {
              // groupList.sort((a, b) => a
              //     .substring(0, 1)
              //     .codeUnitAt(0)
              //     .compareTo(b.substring(0, 1).codeUnitAt(0)));
              if (groupList.length < 3) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text(
                    "A group should have atleast 3 members",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17),
                  ),
                  backgroundColor: Colors.red,
                ));
              } else {
                createGroup(groupList);
              }
            }));
  }
}

class ChatRoomListTile extends StatefulWidget {
  Timestamp lastMessageTs;
  String chatRoomId, myUserName;
  ChatRoomListTile(this.lastMessageTs, this.chatRoomId, this.myUserName,
      {Key key})
      : super(key: key);
  @override
  _ChatRoomListTileState createState() => _ChatRoomListTileState();
}

class _ChatRoomListTileState extends State<ChatRoomListTile> {
  String profilePicUrl = "", name = "", email, username = "";
  getThisUserInfo() async {
    username =
        widget.chatRoomId.replaceAll(widget.myUserName, "").replaceAll("_", "");
    QuerySnapshot querySnapshot = await DatabaseMethods().getUserInfo(username);
    name = "${querySnapshot.docs[0]["name"]}";
    profilePicUrl = "${querySnapshot.docs[0]["imgUrl"]}";
    email = "${querySnapshot.docs[0]["email"]}";
    setState(() {});
  }

  @override
  void initState() {
    getThisUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return profilePicUrl != ""
        ? InkWell(
            onTap: () {
              if (groupList.contains(username)) {
                groupList.remove(username);
                groupListImg.remove(profilePicUrl);
              } else {
                groupList.add(username);
                groupListImg.add(profilePicUrl);
              }
              setState(() {});
            },
            child: Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.all(25),
              color: groupList.contains(username)
                  ? Colors.blue.withOpacity(0.4)
                  : Colors.transparent,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: Image.network(
                      profilePicUrl,
                      height: 50,
                      width: 50,
                    ),
                  ),
                  const SizedBox(
                    width: 20,
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
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 18),
                      )
                    ],
                  )
                ],
              ),
            ),
          )
        : Container();
  }
}
