import 'package:flutter/material.dart';

class DummyCard extends StatelessWidget {
  final String title;
  DummyCard({required this.title});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: <Widget>[Text("$title"), Text("this is text plus $title")],
      ),
    );
  }
}
