import 'package:flutter/material.dart';
import 'package:readsms/readsms.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  final _plugin = Readsms();
  List<SmsData> smsList = [];

  @override
  void initState() {
    super.initState();
    getPermission().then((value) {
      if (value) {
        _plugin.read();
        _plugin.smsStream.listen((event) {
          setState(() {
            SmsData smsData = SmsData(
              body: event.body,
              sender: event.sender,
              timeReceived: event.timeReceived,
            );
            smsList.insert(0, smsData); // Insert new SmsData at the beginning
          });
        });
      }
    });
  }

  Future<bool> getPermission() async {
    if (await Permission.sms.status == PermissionStatus.granted) {
      return true;
    } else {
      if (await Permission.sms.request() == PermissionStatus.granted) {
        return true;
      } else {
        print("permission denied");
        return false;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    _plugin.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('SMS Reader App'),
        ),
        body: ListView.builder(
          itemCount: smsList.length,
          itemBuilder: (context, index) {
            return Card(
              child: ListTile(
                title: Text('Sender: ${smsList[index].sender}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SMS: ${smsList[index].body}'),
                    Text('Time: ${smsList[index].timeReceived.toString()}'),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SmsData {
  final String body;
  final String sender;
  final DateTime timeReceived;

  SmsData({required this.body, required this.sender, required this.timeReceived});
}

