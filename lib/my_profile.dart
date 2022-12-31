import 'package:chat_app/services/database.dart';
import 'package:chat_app/services/sharedPref_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import './services/sharedPref_helper.dart';

class MyProfile extends StatefulWidget {
  @override
  _MyProfileState createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  TextEditingController name = TextEditingController();
  String myName, myProfilePic, myEmail, myUserName, myUserId, myPhone = "";
  bool imgUploading = false;

  void _pickImage(String source) async {
    PickedFile pickImageFile;
    if (source == "camera") {
      pickImageFile = await ImagePicker().getImage(
          source: ImageSource.camera, imageQuality: 50, maxWidth: 250);
    } else {
      pickImageFile = await ImagePicker().getImage(
          source: ImageSource.gallery, imageQuality: 50, maxWidth: 250);
    }
    setState(() {});
    if (pickImageFile != null) {
      imgUploading = true;
      setState(() {});
      DatabaseMethods().uploadImg(pickImageFile, myUserName).then((imgUrl) {
        Map<String, dynamic> userInfoMap = {
          "email": myEmail,
          "username": myUserName,
          "name": myName,
          "imgUrl": imgUrl,
          "phone": myPhone
        };
        DatabaseMethods().updateImg(myUserId, userInfoMap).then((value) {
          SharedPreferenceHelper().saveUserProfileUrl(imgUrl);
          myProfilePic = imgUrl;
          imgUploading = false;
          pickImageFile = null;
          setState(() {});
        });
      });
    }
  }

  onLaunch() async {
    name.text = await SharedPreferenceHelper().getDisplayName();
    myName = name.text;
    myUserName = await SharedPreferenceHelper().getUserName();
    myProfilePic = await SharedPreferenceHelper().getUserProfileUrl();
    myEmail = await SharedPreferenceHelper().getUserEmail();
    myUserId = await SharedPreferenceHelper().getUserId();
    myPhone = await SharedPreferenceHelper().getUserPhone();
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
      body: SingleChildScrollView(
        child: Container(
          padding:
              const EdgeInsets.only(top: 100, bottom: 50, left: 50, right: 50),
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(alignment: AlignmentDirectional.center, children: [
                Stack(alignment: AlignmentDirectional.bottomEnd, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: myProfilePic != ""
                        ? Hero(
                            tag: 'imageHero',
                            child: CachedNetworkImage(
                              imageUrl: myProfilePic,
                              fit: BoxFit.fill,
                              height: 200,
                              width: 200,
                              placeholder: (context, myProfilePic) =>
                                  const Center(
                                child: CircularProgressIndicator(),
                              ),
                              // errorWidget: (context, myProfilePic) => const Icon(Icons.error),
                            ),
                          )
                        : const Center(
                            child: CircularProgressIndicator(),
                          ),
                  ),
                  Positioned(
                    bottom: 15,
                    right: 10,
                    child: InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            backgroundColor: Colors.transparent,
                            shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                              top: Radius.circular(25.0),
                            )),
                            isScrollControlled: true,
                            context: context,
                            builder: (context) => Padding(
                              padding: EdgeInsets.only(
                                  bottom:
                                      MediaQuery.of(context).viewInsets.bottom),
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 5),
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
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 10),
                                      width: 40,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(30),
                                        color: Colors.grey.withOpacity(0.4),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 20, horizontal: 8),
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _pickImage("camera");
                                              },
                                              icon: const Icon(
                                                Icons.camera,
                                                size: 50,
                                              )),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          IconButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                                _pickImage("gallery");
                                              },
                                              icon: const Icon(
                                                Icons.image_rounded,
                                                size: 50,
                                              ))
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
                        },
                        child: const CircleAvatar(
                          backgroundImage: AssetImage("assets/full.png"),
                        )),
                  )
                ]),
                imgUploading
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: Container(
                          height: 200,
                          width: 200,
                          decoration:
                              const BoxDecoration(color: Colors.white38),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : Container()
              ]),
              Container(
                margin: const EdgeInsets.only(top: 40),
                padding: const EdgeInsets.all(10),
                constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height * 0.3),
                decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Name",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey,
                                    fontSize: 20)),
                            const SizedBox(
                              height: 10,
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              child: Text(
                                myName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 25),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          child: GestureDetector(
                            onTap: () {
                              showModalBottomSheet(
                                backgroundColor: Colors.transparent,
                                shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(25.0),
                                )),
                                isScrollControlled: true,
                                context: context,
                                builder: (_) => Padding(
                                  padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                          .viewInsets
                                          .bottom),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 5),
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
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 10),
                                          width: 40,
                                          height: 5,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(30),
                                            color: Colors.grey.withOpacity(0.4),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 30,
                                        ),
                                        const Text(
                                          "Enter Your Name",
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 20, horizontal: 8),
                                          padding: const EdgeInsets.all(15),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.grey.withOpacity(0.15),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: TextField(
                                                  controller: name,
                                                  decoration: InputDecoration(
                                                    border: InputBorder.none,
                                                    labelText: 'Name',
                                                    labelStyle: TextStyle(
                                                      fontSize: 20,
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    icon: const Icon(
                                                        Icons.person),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                height: 10,
                                              ),
                                              MaterialButton(
                                                onPressed: () async {
                                                  if (name.text.isNotEmpty) {
                                                    DatabaseMethods()
                                                        .updateDisplayName(
                                                            name.text)
                                                        .then((value) {
                                                      SharedPreferenceHelper()
                                                          .saveDisplayName(
                                                              name.text);
                                                      Navigator.of(context)
                                                          .pop();

                                                      setState(() {
                                                        myName = name.text;
                                                      });
                                                    });
                                                  }
                                                },
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                elevation: 0,
                                                highlightColor:
                                                    Colors.red.withOpacity(0.3),
                                                highlightElevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(10),
                                                  width: double.infinity,
                                                  child: const Center(
                                                    child: Text(
                                                      "Update",
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
                            },
                            child: const CircleAvatar(
                              backgroundColor: Colors.white,
                              backgroundImage: AssetImage("assets/user.png"),
                            ),
                          ),
                        )
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Email",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 20)),
                        const SizedBox(
                          height: 10,
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.7,
                          child: Text(
                            myEmail,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 25),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
