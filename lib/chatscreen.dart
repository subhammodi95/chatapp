import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/provider.dart';
import 'package:chat_app/services/sharedPref_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';
import 'package:provider/provider.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class ChatScreen extends StatefulWidget {
  final String name, profilePicUrl, chatRoomId;
  ChatScreen(this.name, this.profilePicUrl, this.chatRoomId);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String messageId = "";
  Stream<QuerySnapshot> messageStream, statusStream;
  String myName, myProfilePic, myUserName, myEmail;
  Map<String, dynamic> lastMessageInfoMap = {};
  String names = "";
  String phoneNumber = "";
  String active = "";
  TextEditingController messageTextEditingController = TextEditingController();

  // ScrollController _listScrollController = ScrollController();

  getMyInfoFromSharedPref() async {
    myName = await SharedPreferenceHelper().getDisplayName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myUserName = await SharedPreferenceHelper().getUserName();
    myEmail = await SharedPreferenceHelper().getUserEmail();
  }

  addMessage(bool sendClicked) {
    if (messageTextEditingController.text != "") {
      String message = messageTextEditingController.text;

      var lastMessageTs = DateTime.now();

      Map<String, dynamic> messageInfoMap = {
        "message": message,
        "sendBy": myUserName,
        "name": myName,
        "ts": lastMessageTs,
        "imgUrl": myProfilePic
      };

      //message id
      if (messageId == "") {
        messageId = randomAlphaNumeric(12);
      }

      DatabaseMethods()
          .addMessage(widget.chatRoomId, messageId, messageInfoMap)
          .then((value) {
        if (widget.chatRoomId.split('_').length == 2) {
          lastMessageInfoMap = {
            "lastMessage": message,
            "lastMessageId": messageId,
            "lastMessageSendTs": lastMessageTs,
            "lastMessageSendBy": myUserName
          };
        } else {
          lastMessageInfoMap = {
            "lastMessage": message,
            "lastMessageId": messageId,
            "profileUrl": widget.profilePicUrl,
            "displayName": widget.name,
            "lastMessageSendTs": lastMessageTs,
            "lastMessageSendBy": myUserName
          };
        }
        DatabaseMethods()
            .updateLastMessageSend(widget.chatRoomId, lastMessageInfoMap);

        if (sendClicked) {
          //delete if empty message was sent
          if (messageTextEditingController.text.trim().isEmpty) {
            DatabaseMethods().deleteThisMessage(widget.chatRoomId, messageId);
          }
          messageTextEditingController.text = "";
          //make message id blank to get regenerated on next message send
          messageId = "";
        }
      });
    } else {
      messageId = "";
    }
  }

  Widget chatMessageTile(
      String message, bool sendByMe, String id, String name, String imgUrl) {
    if (sendByMe) {
      name = "You";
    }
    return Dismissible(
      key: UniqueKey(),
      background: Container(
        alignment: sendByMe ? Alignment.centerRight : Alignment.centerLeft,
        child: sendByMe
            ? const Padding(
                padding: EdgeInsets.only(right: 40),
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 30,
                ),
              )
            : const Padding(
                padding: EdgeInsets.only(left: 40),
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 30,
                ),
              ),
      ),
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        // width: MediaQuery.of(context).size.width,
        child: Row(
          mainAxisAlignment:
              sendByMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          // mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
                alignment: sendByMe ? Alignment.topLeft : Alignment.topRight,
                overflow: Overflow.visible,
                children: [
                  FittedBox(
                    child: Container(
                      // constraints: BoxConstraints(
                      //     maxWidth: MediaQuery.of(context).size.width * .75),
                      alignment: FractionalOffset.center,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 5),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(24),
                              bottomRight: sendByMe
                                  ? const Radius.circular(0)
                                  : const Radius.circular(24),
                              topRight: const Radius.circular(24),
                              bottomLeft: sendByMe
                                  ? const Radius.circular(24)
                                  : const Radius.circular(0)),
                          color: sendByMe ? Colors.blue : Colors.grey),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: sendByMe
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          widget.chatRoomId.split('_').length != 2
                              ? Container(
                                  margin: const EdgeInsets.all(2),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.purple),
                                  ),
                                )
                              : Container(),
                          Text(
                            message,
                            style: TextStyle(
                                color: sendByMe ? Colors.white : Colors.black),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                      top: -15,
                      // right: 40,
                      child: CircleAvatar(
                        backgroundImage: NetworkImage(imgUrl),
                      ))
                ]),
          ],
        ),
      ),
      onDismissed: (direction) async {
        DocumentSnapshot s =
            await DatabaseMethods().getChatRoomInfo(widget.chatRoomId);
        await DatabaseMethods()
            .deleteThisMessage(widget.chatRoomId, id)
            .then((value) {
          if (s["lastMessageId"] == id) {
            Map<String, dynamic> lastMessageInfoMap = {
              "lastMessage": "Message Deleted",
              "lastMessageId": "",
              "lastMessageSendTs": DateTime.now(),
              "lastMessageSendBy": myUserName
            };

            DatabaseMethods()
                .updateLastMessageSend(widget.chatRoomId, lastMessageInfoMap);
          }
        });
      },
    );
  }

  Widget chatMessages() {
    return StreamBuilder(
        stream: messageStream,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapShot) {
          // SchedulerBinding.instance.addPostFrameCallback((_) {
          //   _listScrollController.animateTo(
          //       _listScrollController.position.minScrollExtent,
          //       duration: Duration(milliseconds: 250),
          //       curve: Curves.easeInOut);
          // });
          return snapShot.hasData
              ? ListView.builder(
                  padding: const EdgeInsets.only(bottom: 70, top: 16),
                  itemCount: snapShot.data.docs.length,
                  reverse: true,
                  // controller: _listScrollController,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapShot.data.docs[index];
                    return chatMessageTile(
                        ds["message"],
                        myUserName == ds["sendBy"],
                        ds.id,
                        ds["name"],
                        ds["imgUrl"]);
                  })
              : const Center(
                  child: CircularProgressIndicator(),
                );
        });
  }

  getAndSetMessages() async {
    messageStream =
        await DatabaseMethods().getChatRoomMessages(widget.chatRoomId);
    statusStream = await FirebaseFirestore.instance
        .collection("users")
        .where("username",
            isEqualTo: widget.chatRoomId
                .replaceAll('_', '')
                .replaceAll(myUserName, ''))
        .snapshots();
    if (widget.chatRoomId.split('_').length != 2) {
      names = await DatabaseMethods().getGroupMembers(widget.chatRoomId);
    } else {
      QuerySnapshot snapshot = await DatabaseMethods().getUserInfo(
          widget.chatRoomId.replaceAll('_', '').replaceAll(myUserName, ''));
      phoneNumber = "${snapshot.docs[0]["phone"]}";
    }

    setState(() {});
  }

  doThisOnLaunch() async {
    await getMyInfoFromSharedPref();

    getAndSetMessages();
  }

  @override
  void initState() {
    doThisOnLaunch();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          widget.chatRoomId.split('_').length == 2
              ? Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: InkWell(
                    child: Icon(
                      Icons.phone,
                      size: 30,
                      color: phoneNumber == "" || phoneNumber == null
                          ? Colors.white54
                          : Colors.white,
                    ),
                    onTap: () async {
                      if (phoneNumber != "" || phoneNumber != null) {
                        await FlutterPhoneDirectCaller.callNumber(phoneNumber);
                      }
                    },
                  ),
                )
              : Container()
        ],
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Hero(
                  tag: 'chatImage',
                  child: Image.network(widget.profilePicUrl,
                      height: 40, width: 40)),
            ),
            const SizedBox(
              width: 10,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name),
                names != ""
                    ? SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Text(
                          names,
                          style: const TextStyle(fontSize: 10),
                        ),
                      )
                    : StreamBuilder(
                        stream: statusStream,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapShot) {
                          if (snapShot.connectionState ==
                              ConnectionState.active) {
                            if (snapShot.hasData) {
                              DocumentSnapshot ds = snapShot.data.docs[0];
                              return ds["active"] == "1"
                                  ? const Text(
                                      "Active",
                                      style: TextStyle(fontSize: 15),
                                    )
                                  : const Text(
                                      "Inactive",
                                      style: TextStyle(
                                          fontSize: 15,
                                          color: Color.fromARGB(
                                              249, 238, 229, 229)),
                                    );
                            } else {
                              return Container();
                            }
                          } else {
                            return Container();
                          }
                        }),
              ],
            ),
          ],
        ),
      ),
      body: Stack(
        //wrap with container if error
        children: [
          chatMessages(),
          Container(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                    controller: messageTextEditingController,
                    onChanged: (value) async {
                      await Provider.of<Btn>(context, listen: false)
                          .changeBtn();
                      addMessage(false);
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type a Message",
                        hintStyle:
                            TextStyle(color: Colors.white.withOpacity(0.6))),
                  )),
                  GestureDetector(
                      onTap: () async {
                        addMessage(true);

                        await Provider.of<Btn>(context, listen: false)
                            .changeBtn();
                      },
                      child: Consumer<Btn>(
                        builder: (ctx, provider, _) => Icon(
                          Icons.send,
                          color: messageTextEditingController.text.isEmpty
                              ? Colors.white.withOpacity(0.5)
                              : Colors.white,
                        ),
                      ))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
