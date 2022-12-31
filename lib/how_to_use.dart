import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HowToUse extends StatelessWidget {
  const HowToUse({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Instructions"),
      ),
      body: Container(
        child: Column(
          children: const [
            Text(
              "To delete a Message",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 20,
            ),
            Text(
              "To delete a message swipe the messages left or right",
              style: TextStyle(fontSize: 25),
            ),
            SizedBox(
              height: 30,
            ),
            Text(
              "--More to be Added--",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
