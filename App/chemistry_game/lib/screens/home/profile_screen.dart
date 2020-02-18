import 'dart:async';


import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:nice_button/NiceButton.dart';

class ProfileScreen extends StatefulWidget {
  final userId;

  ProfileScreen({this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState(userId: userId);
}

class _ProfileScreenState extends State<ProfileScreen> {

  var userId;
  _ProfileScreenState({this.userId});

  var userName = new ValueNotifier<String>("");
  var singleGameWins = "";
  var teamGameWins = "";



  final HttpsCallable callGetProfileData = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getProfileData',
  );

  var userToken;
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  @override
  Future<void> initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        var title = message["notification"]["title"];

        switch(title) {
          case ("Profile Data"):
            userName.value = message["data"]["userName"];
            singleGameWins = message["data"]["singleGameWins"];
            teamGameWins = message["data"]["teamGameWins"];
            break;
          default:
        }

        return;
      }
    );
    _firebaseMessaging.getToken().then((token) async {
      userToken = token;
      print("Token : $userToken");

      var data = {
        "userToken": userToken,
        "userId": userId
      };
//      await callGetProfileData(data);
    });
  }


  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;



    Widget drawProfileData(String username, String singleGameWins, String teamGameWins) {
      return Row(
        children: <Widget>[
          Container(
            height: mediaQueryHeight * 0.5,
            child: new LayoutBuilder(builder: (context, constraint) {
              return new Icon(Icons.person, size: constraint.biggest.height);
            }),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Name: " + username),
                Text("Single Game Wins: " + singleGameWins),
                Text("Team Game Wins: " + teamGameWins),
              ],
            ),
          ),

        ],
      );
    }

    return ValueListenableBuilder(
      child: Container(
        child: drawProfileData(userName.value, singleGameWins, teamGameWins)),
      valueListenable: userName,
      builder: (BuildContext context, String value , Widget child) {
        return drawProfileData(userName.value, singleGameWins, teamGameWins);
      },
    );
      /*Column(
        children: <Widget>[
          RaisedButton(
            onPressed: () {
              startTimer();
            },
            child: Text("start"),
          ),
          Text("$_start"),
          RaisedButton(
            child: Text("add"),
            onPressed: () async {
              var data = {
                "name": "Cl",
                "uuid": "sasasa"
              };

              await callAddValue.call(data);
            },
          ),
          RaisedButton(
            child: Text("delete"),
            onPressed: () async {
              var data = {
                "name": "Cl",
                "uuid": "sasasa"
              };

              await callDeleteValue.call(data);
            },
          ),
          RaisedButton(
            child: Text("get"),
            onPressed: () async {
              var data = {
                "name": "Cl",
                "uuid": "ss"
              };

              await callGetValue.call(data);
            },
          )
        ],
      ),
    );*/
  }
}