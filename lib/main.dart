import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _Home createState() {
    return _Home();
  }
}

class _Home extends State<Home> {
  int counter = 1;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
                flex: 6,
                child: Container(
                  color: Colors.greenAccent,
                  child: Center(
                    child: Text("count $counter"),
                  ),
                )),
            Expanded(
                flex: 4,
                child: Container(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text("This is something cool"),
                    TextButton(
                        onPressed: () {
                          setState(() {
                            counter += 1;
                          });
                          print("the count is $counter");
                        },
                        child: Text("Press me 2")),
                  ],
                ))),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(
            Icons.sms,
            color: Colors.white,
          ),
          onPressed: () {
            print("fetched sms");
          },
          backgroundColor: Colors.green,
        ));
  }
}
