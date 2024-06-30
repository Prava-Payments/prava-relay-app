import 'package:flutter/material.dart';
import 'package:readsms/readsms.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:background_sms/background_sms.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  final _plugin = Readsms();
  String? instruction;
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

            // Check for specific content and send API request
            print(smsData.body);
            if (smsData.body.contains("Sarva")) {
              print("-----------trying to reach server-----------------");
              instruction = extractInstRegex(smsData.body);
              if (instruction != null) {
                if (instruction == 'signup') {
                  sendSignUpRequest(instruction, smsData.sender);
                }
                print(instruction);
                if (instruction == 'sendETH') {
                  String? wallet, session, token;

                  final walletRegex = RegExp(r'wallet:\s*([a-zA-Z0-9]+)');
                  final sessionRegex = RegExp(r'session:\s*([a-zA-Z0-9]+)');
                  final tokenRegex = RegExp(r'token:\s*([0-9]*\.?[0-9]+)');

                  final walletMatch = walletRegex.firstMatch(smsData.body);
                  if (walletMatch != null && walletMatch.groupCount > 0) {
                    wallet = walletMatch.group(1);
                  }

                  final sessionMatch = sessionRegex.firstMatch(smsData.body);
                  if (sessionMatch != null && sessionMatch.groupCount > 0) {
                    session = sessionMatch.group(1);
                  }

                  final tokenMatch = tokenRegex.firstMatch(smsData.body);
                  if (tokenMatch != null && tokenMatch.groupCount > 0) {
                    token = tokenMatch.group(1);
                  }

                  print({session, wallet, token});
                  sendETHUpRequest(
                      instruction, smsData.sender, wallet, session, token);
                }
              } else {
                print("No public address found in the SMS content.");
              }
            }
          });
        });
      }
    });
  }

  String? extractEncodeMsg(String messageContent) {
    try {
      final base64Part =
          messageContent.substring(messageContent.indexOf("Sarva") + 5).trim();
      final decodedBytes = base64Decode(base64Part);
      final decodedMessage = utf8.decode(decodedBytes);

      // Extract the instruction from the decoded message
      final instruction = decodedMessage
          .split(", ")
          .firstWhere((part) => part.startsWith("inst:"))
          .split(":")[1];
      return instruction;
    } catch (e) {
      print("Error decoding message: $e");
      return null;
    }
  }

  String? extractInstRegex(String body) {
    final instRegex = RegExp(r'inst:\s*([a-zA-Z0-9]+)');
    final instMatch = instRegex.firstMatch(body);

    if (instMatch != null && instMatch.groupCount > 0) {
      return instMatch.group(1);
    }

    return '';
  }

  Future<void> sendETHUpRequest(String? instruction, String sender,
      String? destination, String? session, String? token) async {
    print("you're trying to send eth");
    final url =
        'https://sarva-backend-production.up.railway.app/api/instructions';
    print(sender);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': sender,
          'instruction': instruction,
          'session': session,
          'destination': destination,
          'amount': token,
        }),
      );
      if (response.statusCode == 200) {
        print("----------------Message sent successfully-------------------");
        final responseBody = jsonDecode(response.body);
        String ethBalance = responseBody["Balance"]["ETH"];
        double? newEth = double.parse(ethBalance) - double.parse(token!);
        String usdcBalance = responseBody["Balance"]["USDC"];
        String sessionStr = responseBody["session"];
        String address = responseBody["deployedWallet"];

        sendUpdateSMS(
            sender, newEth.toString(), usdcBalance, sessionStr, address);
      } else {
        print("Failed to send message: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> sendSignUpRequest(String? instruction, String sender) async {
    final url =
        'https://sarva-backend-production.up.railway.app/api/instructions';
    print(sender);
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'sender': sender, 'instruction': instruction}),
      );
      if (response.statusCode == 200) {
        print("----------------Message sent successfully-------------------");
        final responseBody = jsonDecode(response.body);
        String ethBalance = responseBody["Balance"]["ETH"];
        String usdcBalance = responseBody["Balance"]["USDC"];
        String sessionStr = responseBody["session"];
        String address = responseBody["deployedWallet"];

        sendSignUpSMS(sender, ethBalance, usdcBalance, sessionStr, address);
      } else {
        print("Failed to send message: ${response.statusCode}");
        print("Response body: ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  Future<void> sendSignUpSMS(String sender, String eth, String usdc,
      String session, String addr) async {
    try {
      await BackgroundSms.sendMessage(
        phoneNumber: sender,
        message:
            "Sarva, from: relay, to: client, balance: ETH: $eth, USDC: $usdc, session: $session, wallet: $addr",
      );
      print("Confirmation SMS sent successfully");
    } catch (e) {
      print("Failed to send confirmation SMS: $e");
    }
  }

  Future<void> sendUpdateSMS(String sender, String eth, String usdc,
      String session, String addr) async {
    try {
      await BackgroundSms.sendMessage(
        phoneNumber: sender,
        message:
            "Sarva, from: relay, to: client, balance: ETH: $eth, USDC: $usdc, session: $session, wallet: $addr",
      );
      print("Confirmation SMS sent successfully");
    } catch (e) {
      print("Failed to send confirmation SMS: $e");
    }
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

  SmsData(
      {required this.body, required this.sender, required this.timeReceived});
}
