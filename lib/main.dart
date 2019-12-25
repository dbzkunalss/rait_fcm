import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlutterBase',
      home: Scaffold(
        body: MessageHandler(),
      ),
    );
  }
}

class MessageHandler extends StatefulWidget {
  @override
  _MessageHandlerState createState() => _MessageHandlerState();
}

class _MessageHandlerState extends State<MessageHandler> {
  final Firestore _db = Firestore.instance;
  final FirebaseMessaging _fcm = FirebaseMessaging();
  bool v1, v2, v3, v4;

  List<bool> inputs = List<bool>();
  StreamSubscription iosSubscription;

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      iosSubscription = _fcm.onIosSettingsRegistered.listen((data) {
        print(data);
        _saveDeviceToken();
      });

      _fcm.requestNotificationPermissions(IosNotificationSettings());
    } else {
      _saveDeviceToken();
      setState(() {
        for (int i = 0; i < 5; i++) {
          inputs.add(false);
        }
      });
    }

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
        // final snackbar = SnackBar(
        //   content: Text(message['notification']['title']),
        //   action: SnackBarAction(
        //     label: 'Go',
        //     onPressed: () => null,
        //   ),
        // );

        // Scaffold.of(context).showSnackBar(snackbar);
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: ListTile(
              title: Text(message['notification']['title']),
              subtitle: Text(message['notification']['body']),
            ),
            actions: <Widget>[
              FlatButton(
                color: Colors.amber,
                child: Text('Ok'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        // TODO optional
      },
      onResume: (Map<String, dynamic> message) async {
        print("onResume: $message");
        // TODO optional
      },
    );
  }

  void itemChange(bool val, int index) {
    setState(() {
      inputs[index] = val;
    });
  }

  @override
  void dispose() {
    if (iosSubscription != null) iosSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // _handleMessages(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrange,
        title: Text('FCM Push Notifications'),
      ),
      body: ListView.builder(
          itemCount: inputs.length,
          itemBuilder: (BuildContext context, int index) {
            return Card(
              child: Container(
                padding: EdgeInsets.all(10.0),
                child: Column(
                  children: <Widget>[
                    CheckboxListTile(
                        value: inputs[index],
                        title: Text('item $index'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (bool val) {
                          itemChange(val, index);
                        }),
                    RaisedButton(
                      child: Text("SUBMIT"),
                      onPressed: () {
                        for (var i = 0; i < 5; i++) {
                          if (inputs[i] == true) {
                            _subscribeToTopic(i.toString());
                          }
                        }
                      },
                    )
                  ],
                ),
              ),
            );
          }),
    );
  }

  /// Get the token, save it to the database for current user
  _saveDeviceToken() async {
    // Get the current user
    String uid = DateTime.now().millisecondsSinceEpoch.toString();
    // FirebaseUser user = await _auth.currentUser();

    // Get the token for this device
    String fcmToken = await _fcm.getToken();

    // Save it to Firestore
    if (fcmToken != null) {
      var tokens = _db
          .collection('users')
          .document(uid)
          .collection('tokens')
          .document(fcmToken);

      await tokens.setData({
        'token': fcmToken,
        'createdAt': FieldValue.serverTimestamp(), // optional
        'platform': Platform.operatingSystem // optional
      });
    }
  }

  /// Subscribe the user to a topic
  _subscribeToTopic(String topic) async {
    // Subscribe the user to a topic
    _fcm.subscribeToTopic(topic);
  }
}
