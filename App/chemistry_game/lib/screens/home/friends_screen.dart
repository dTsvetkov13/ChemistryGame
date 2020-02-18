import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chemistry_game/constants/text_styling.dart';
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

  final HttpsCallable callGetAllFriends = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getAllFriends',
  );

  final HttpsCallable callAddFriend = CloudFunctions.instance.getHttpsCallable(
    functionName: 'addFriend',
  );

  final HttpsCallable callAcceptInvitation = CloudFunctions.instance.getHttpsCallable(
    functionName: 'acceptInvitation',
  );

  final HttpsCallable callDeclineInvitation = CloudFunctions.instance.getHttpsCallable(
    functionName: 'declineInvitation',
  );

  final HttpsCallable callGetAllInvitations = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getAllInvitations',
  );

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String playerToken;

  @override
  void initState() {
    print("Friends");
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
      print("Token : $playerToken");

      showToast("Wait to load all friend");

      var data = {
        "userId": userId
      };

      Result.value = (await callGetAllFriends.call(data)).data;
    });
  }

  TextEditingController usernameController = TextEditingController();
  var username = "";

  var friends = new ValueNotifier<List<Widget>>(null);
  var Result = new ValueNotifier([]);

  void showToast(var toastMsg){
    Fluttertoast.showToast(
        msg: toastMsg.toString(),
        timeInSecForIos: 10, //TODO: set it back to 1/2 sec
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT
    );
  }

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    void drawInvitations(double width, double height) async {

      var data = {
        "userId": userId
      };
      var result = await callGetAllInvitations.call(data);
      var invitations = result.data;

      if(invitations.length <= 0) {
        showToast("There are not invitations");
        return;
      }
      print("Invitations: " + invitations[0]);

      List<Widget> users = new List<Widget>();

      for(int i = 0; i < invitations.length; i++)
      {
        print(invitations[i]);
        users.add(
            Container(
              width: width,
              height: height * 0.2,
              child: Row(
                children: <Widget>[
                  Container(
                    width: width * 0.6,
                    height: height * 0.2,
                    child: Center(
                      child: Text(
                          invitations[i].toString()
                      ),
                    ),
                    color: Colors.blueGrey,
                  ),
                  Container(
                    width: width * 0.2,
                    height: height * 0.2,
                    child: IconButton(
                      icon: Icon(Icons.check),
                      color: Colors.green,
                      onPressed: () {
                        print(invitations[i]);
                        var data = {
                          "friendUsername": invitations[i],
                          "userId": userId
                        };

                        callAcceptInvitation.call(data);

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

                        callDeclineInvitation.call(data);
                      },
                    ),
                  )
                ],
              ),
              color: Colors.yellowAccent,
            ));
      }

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Center(child: Text("Invitations")),
            content: Container(
              width: width,
              height: height * 0.9,
              child: ListView(
                  scrollDirection: Axis.vertical,
                  children: users
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
              background: Colors.white70,
              textColor: Colors.black,
              width: mediaQueryWidth * 0.3,
              text: "Show invitations",
              onPressed: () async {
                drawInvitations(mediaQueryWidth * 0.8, mediaQueryHeight * 0.7);
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
              color: Colors.blue,
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
      List<Widget> friends = new List<Widget>();

      for(int i = 0; i < Result.value.length; i++) {
        print("Friend: " + Result.value[i]["username"]);
        friends.add(drawUserData(mediaQueryWidth * 0.2, mediaQueryHeight * 0.8, Result.value[i]["username"],
                                    Result.value[i]["singleGameWins"], Result.value[i]["teamGameWins"]));
      }

      return Container(
        width: mediaQueryWidth,
        height: mediaQueryHeight * 0.6,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: friends
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
                background: Colors.white70,
                textColor: Colors.black,
                width: mediaQueryWidth * 0.2,
                text: "Invite a friend",
                onPressed: () async {
                  print(username);

                  var data = {
                    "userId": userId,
                    "friendUsername": username
                  };

                  await callAddFriend.call(data);
                },
              ),
            )
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
