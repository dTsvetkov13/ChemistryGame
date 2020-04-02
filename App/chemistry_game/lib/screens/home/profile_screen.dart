import 'dart:async';
import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:chemistry_game/models/remote_config.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:badges/badges.dart';

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



  final HttpsCallable callGetProfileData = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'getProfileData',
  );

  final HttpsCallable callTest = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'testFunction1',
  );

  var userToken;
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  ConfettiController _controllerCenterLeft;
  ConfettiController _controllerCenterRight;

  @override
  void dispose() {
    _controllerCenterRight.dispose();
    _controllerCenterLeft.dispose();
    super.dispose();
  }

  @override
  // ignore: missing_return
  Future<void> initState() {
    super.initState();
    _controllerCenterRight =
        ConfettiController(duration: Duration(seconds: 10));
    _controllerCenterLeft = ConfettiController(duration: Duration(seconds: 10));
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

    MaterialApp(
      title: "Test Theme",
      theme: ThemeData(
        primaryColor: Colors.lightGreenAccent,
        accentColor: Colors.cyan,
      )
    );

    Widget drawRightSideAddCardButton(double width, double height) {
      return Container(
        width: width,
        height: height,

        child: RaisedButton(
          color: Colors.white,
          child: Icon(Icons.add),
          onPressed: () {
            var fu = CloudFunctions(region: "europe-west1").getHttpsCallable(
              functionName: "getProfileData",
            );
            //print("Width: " + width.toString() + ", height: " + height.toString());
//            exists.value = true;
//            var newId = new Uuid();
//            rightSideCards[newId] = null;
//            updated.value = !updated.value;
          },
        ),
      );
    }

    double width = 100;
    double height = 100;

    return Column(

      children: <Widget>[
        Badge(
          badgeContent: Text('3'),
          child: Container(
            child: Text(
                "dsdsd"
            ),
          ),
        )
      ],

    );
  }
}