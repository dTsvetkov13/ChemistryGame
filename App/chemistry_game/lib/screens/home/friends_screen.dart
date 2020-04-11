import 'package:chemistry_game/models/profile_data.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nice_button/NiceButton.dart';

class FriendsScreen extends StatefulWidget {
  final userId;

  FriendsScreen({this.userId});

  @override
  _FriendsScreenState createState() => _FriendsScreenState(userId: userId);
}

class _FriendsScreenState extends State<FriendsScreen> {

  final userId;

  _FriendsScreenState({this.userId});

  final HttpsCallable callGetAllFriends = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'getAllFriends',
  );

  final HttpsCallable callAddFriend = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'addFriend',
  );

  final HttpsCallable callAcceptInvitation = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'acceptInvitation',
  );

  final HttpsCallable callDeclineInvitation = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'declineInvitation',
  );

  final HttpsCallable callGetAllInvitations = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'getAllInvitations',
  );

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String playerToken;

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) {
        var data = message["notification"];
        print("Message received: $data");

        if(message.containsKey('data'))
        {
          var msgData = message['data']['cardToAdd'];
          print("Message Data: $msgData");
        }

        return;
      }
    );
    _firebaseMessaging.getToken().then((token) async {
      playerToken = token;
      showToast("Wait to load all friend");

      var data = {
        "userId": userId
      };

      Result.value = (await callGetAllFriends.call(data)).data;

      if(Result.value.length == 0){
        showToast("There are no friends to show.");
      }
    });
  }

  TextEditingController usernameController = TextEditingController();
  var username = "";

  var friends = new ValueNotifier<List<Widget>>(null);
  var Result = new ValueNotifier([]);
  bool thereAreNotInvitationsMsgShown = false;

  void showToast(var toastMsg){
    Fluttertoast.showToast(
        msg: toastMsg.toString(),
        timeInSecForIos: 10,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT
    );
  }

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    var theme = Theme.of(context);

    void drawInvitations(double width, double height) async {

      var data = {
        "userId": userId
      };
      var result = await callGetAllInvitations.call(data);
      var invitations = result.data;

      if(invitations.length <= 0 && !thereAreNotInvitationsMsgShown) {
        thereAreNotInvitationsMsgShown = true;
        showToast("There are not invitations");
        return;
      }

      ValueNotifier<bool> updated = ValueNotifier(false);
      List<String> playerNames = new List<String>();

      for(int i = 0; i < invitations.length; i++) {
        playerNames.add(invitations[i].toString());
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(child: Text("Invitations")),
            content: Container(
              width: width,
              height: height * 0.9,
              child: ValueListenableBuilder(
                valueListenable: updated,
                builder: (BuildContext context, bool value, Widget child) {
                  return ListView.builder(
                    scrollDirection: Axis.vertical,
                    itemCount: playerNames.length,
                    itemBuilder: (BuildContext context, int i) {
                      return new Container(
                        width: width,
                        height: height * 0.2,
                        child: Row(
                          children: <Widget>[
                            Container(
                              width: width * 0.6,
                              height: height * 0.2,
                              child: Center(
                                child: Text(
                                  playerNames[i].toString()
                                ),
                              ),
                              color: primaryGreen,
                            ),
                            Container(
                              width: width * 0.2,
                              height: height * 0.2,
                              child: IconButton(
                                icon: Icon(Icons.check),
                                color: Colors.green,
                                onPressed: () {
                                  var data = {
                                    "friendUsername": playerNames[i],
                                    "userId": userId
                                  };
                                  playerNames.removeAt(i);
                                  callAcceptInvitation.call(data);
                                  updated.value = !updated.value;
                                  showToast("Invitation accepted");
                                },
                              ),
                            ),
                            Container(
                              width: width * 0.2,
                              height: height * 0.2,
                              child: IconButton(
                                icon: Icon(Icons.delete),
                                color: Colors.red,
                                onPressed: () {
                                  var data = {
                                    "friendUsername": playerNames[i],
                                    "userId": userId
                                  };
                                  playerNames.removeAt(i);
                                  updated.value = !updated.value;
                                  callDeclineInvitation.call(data);
                                  showToast("Invitation declined");
                                },
                              ),
                            )
                          ],
                        ),
                        color: primaryPurple,
                      );
                    },
                  );
                },
                child: ListView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: playerNames.length,
                  itemBuilder: (BuildContext context, int i) {
                    return Container(
                      width: width,
                      height: height * 0.2,
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: width * 0.6,
                            height: height * 0.2,
                            child: Center(
                              child: Text(
                                  playerNames[i].toString()
                              ),
                            ),
                            color: primaryGreen,
                          ),
                          Container(
                            width: width * 0.2,
                            height: height * 0.2,
                            child: IconButton(
                              icon: Icon(Icons.check),
                              color: Colors.green,
                              onPressed: () {
                                var data = {
                                  "friendUsername": invitations[i],
                                  "userId": userId
                                };
                                playerNames.removeAt(i);
                                callAcceptInvitation.call(data);
                                updated.value = !updated.value;
                              },
                            ),
                          ),
                          Container(
                            width: width * 0.2,
                            height: height * 0.2,
                            child: IconButton(
                              icon: Icon(Icons.delete),
                              color: Colors.red,
                              onPressed: () {
                                var data = {
                                  "friendUsername": invitations[i],
                                  "userId": userId
                                };
                                playerNames.removeAt(i);
                                callDeclineInvitation.call(data);
                                updated.value = !updated.value;
                              },
                            ),
                          )
                        ],
                      ),
                      color: primaryPurple,
                    );
                  },
                ),
              ),
            ),
          );
        },
      );
    }


    Widget topBar() {
      return Container(
        width: mediaQueryWidth,
        height: mediaQueryHeight * 0.15,
        child: Row(
         children: <Widget> [
          Container(
            width: mediaQueryWidth * 0.2,
            child: Center(
              child: Text(
                "Friends",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
            ),
          ),
          Container(
            width: mediaQueryWidth * 0.1,
          ),
          Column(
            children: <Widget>[
              Container(
                width: mediaQueryWidth * 0.3,
                child: TextFormField(
                  keyboardType: TextInputType.text,
                  controller: usernameController,
                  onChanged: (val) {
                    setState(() {
                      username = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: "Friend username"
                  ),
                ),
              )
            ],
          ),
          Container(
            width: mediaQueryWidth * 0.05,
          ),
          Container(
            width: mediaQueryWidth * 0.3,
            child: NiceButton(
              elevation: 1.0,
              radius: 52.0,
              background: theme.buttonColor,
              textColor: Colors.black,
              text: "Invite a friend",
              onPressed: () async {
                if(username == ProfileData.name) {
                  showToast("You cannot add yourself as a friend!");
                  return;
                }
                var data = {
                  "userId": userId,
                  "friendUsername": username
                };
                await callAddFriend.call(data);
                username = "";
                showToast("Invitation sent to the user");
              },
            ),
          ),
         ]
        )
      );
    }

    Widget drawUserData(double width, double height, String username, String singleGameWins, String teamGameWins) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          border: new Border.all(
              color: primaryGreen,
              width: 5.0,
              style: BorderStyle.solid
          ),
          borderRadius: new BorderRadius.all(new Radius.circular(10.0))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.person),
            Text(
              username,
              style: TextStyle(
                  fontWeight: FontWeight.bold
              ),
            ),
            Text("Single Game Wins: " + singleGameWins),
            Text("Team Game Wins: " + teamGameWins)
          ]
        ),
      );
    }

    Widget friendsData() {
      return Container(
        width: mediaQueryWidth,
        height: mediaQueryHeight * 0.6,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: Result.value.length,
          itemBuilder: (BuildContext context, int i) {
            return drawUserData(mediaQueryWidth * 0.2, mediaQueryHeight * 0.8, Result.value[i]["username"],
                Result.value[i]["singleGameWins"], Result.value[i]["teamGameWins"]);
          },
        ),
      );
    }

    return Column(
      children: <Widget>[
        topBar(),
        Column(
          children: <Widget>[
            Container(
              width: mediaQueryWidth * 0.3,
            ),
            Container(
              width: mediaQueryWidth * 0.3,
              child: NiceButton(
                elevation: 1.0,
                radius: 52.0,
                background: theme.buttonColor,
                textColor: Colors.black,
                text: "Invitations",
                onPressed: () async {
                  drawInvitations(mediaQueryWidth * 0.8, mediaQueryHeight * 0.7);
                },
              ),
            ),
          ],
        ),
        Container(
          height: mediaQueryHeight * 0.05,
        ),
        ValueListenableBuilder(
          valueListenable: Result,
          builder: (BuildContext context, var value, Widget child) {
            return friendsData();
          },
          child: friendsData(),
        )
      ],
    );
  }
}
