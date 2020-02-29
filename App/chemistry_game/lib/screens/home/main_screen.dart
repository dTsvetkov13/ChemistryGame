import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/fieldPlayer.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/profile_data.dart';
import 'package:chemistry_game/screens/home/home.dart';
import 'package:chemistry_game/screens/loading_screen.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nice_button/nice_button.dart';
import 'package:provider/provider.dart';

enum gameType {
  singleGame,
  teamGame
}

class MainScreen extends StatefulWidget {

  final String userId;

  MainScreen({this.userId});


  @override
  _MainScreenState createState() => _MainScreenState(userId: userId);
}

class _MainScreenState extends State<MainScreen> {

  final String userId;

  _MainScreenState({this.userId});

  static Map<gameType, Widget> gameTypeWindow = {
    gameType.singleGame: createGameWindow("Single Mode"),
    gameType.teamGame: createGameWindow("Team Mode"),
  };

  static ValueNotifier<int> currentIndex = ValueNotifier<int>(0);
  static ValueNotifier<gameType> currGT = ValueNotifier<gameType>(gameType.singleGame);

  static List<gameType> types = [
    gameType.singleGame, gameType.teamGame
  ];

  static Text createGameWindow(String text) {
    return Text(
      text,
      style: optionStyle,
    );
  }

  final HttpsCallable callFindRoom = CloudFunctions.instance.getHttpsCallable(
    functionName: 'findRoom',
  );

  final HttpsCallable callGetPlayerCards = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getPlayerCards',
  );

  final HttpsCallable callReadyPlayer = CloudFunctions.instance.getHttpsCallable(
    functionName: 'readyPlayer',
  );

  final HttpsCallable callAcceptTeamInvitation = CloudFunctions.instance.getHttpsCallable(
    functionName: 'acceptTeamInvitation',
  );

  final HttpsCallable callGetProfileData = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getProfileData',
  );

  final HttpsCallable callGetAllFriends = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getAllFriends',
  );

  final HttpsCallable callGetAllInvitations = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getAllInvitations',
  );

  final HttpsCallable callGetTopTen = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getTopTen',
  );

  final HttpsCallable callUpdateCurrToken = CloudFunctions.instance.getHttpsCallable(
    functionName: 'updateCurrToken',
  );

  final HttpsCallable callSendTeamGameInvitation = CloudFunctions.instance.getHttpsCallable(
    functionName: 'sendTeamGameInvitation',
  );

  final HttpsCallable callGetOnlineFriends = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getOnlineFriends',
  );

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String userToken;

  var roomId;
  var lastCard;
  var playersNames;
  var playerName = "";
  bool playBtnCalled = false;

  @override
  void initState() {
    print("built");
    super.initState();
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
          var data = message["notification"];
          print("Message received in main screen: $data");

          switch(data["title"])
          {
            case("Game Started") :
              roomId = message["data"]["roomId"];
              lastCard = message["data"]["lastCard"];
              playersNames = message["data"]["playersNames"];

              var receivedData = (await callGetPlayerCards({"playerId": userId})).data; //, "playerToken": userToken

              var elementCards = receivedData["elementCards"];
              var compoundCards = receivedData["compoundCards"];
              playerName = receivedData["playerName"];

              print("Element Cards: " + elementCards);
              print("Compound Cards: " + compoundCards);
              print(getPlayerNames(playersNames));

              var playerNames = getPlayerNames(playersNames);

              Player player = new Player(playerName, userId, elementCards, compoundCards);

              var fieldPlayers = new List<FieldPlayer>();
              playerNames.forEach((name) {
                fieldPlayers.add(
                    new FieldPlayer(name: name, cardsNumber: player.elementCards.length)
                );
              });

              lastCard = lastCard.split(",");

              ElementCard lastCardData = new ElementCard(name: lastCard[0], group: lastCard[1], period: int.parse(lastCard[2]));

              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuildRoomScreen(roomId: roomId, playerId: userId, lastCardData: lastCardData,
                    player: player, firebaseMessaging: _firebaseMessaging, fieldPlayers: fieldPlayers,))
              );
              await callReadyPlayer.call({"roomId": roomId});
              break;
            case("Join Room") :

              break;
            case("Player Cards") : //Delete this case
              var elementCards = message["data"]["elementCards"];
              var compoundCards = message["data"]["compoundCards"];
              playerName = message["data"]["playerName"];

              print("Element Cards: " + elementCards);
              print("Compound Cards: " + compoundCards);
              print(getPlayerNames(playersNames));

              var playerNames = getPlayerNames(playersNames);

              Player player = new Player(playerName, userId, elementCards, compoundCards);

              var fieldPlayers = new List<FieldPlayer>();
              playerNames.forEach((name) {
                fieldPlayers.add(
                  new FieldPlayer(name: name, cardsNumber: player.elementCards.length)
                );
              });

              lastCard = lastCard.split(",");

              ElementCard lastCardData = new ElementCard(name: lastCard[0], group: lastCard[1], period: int.parse(lastCard[2]));

              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuildRoomScreen(roomId: roomId, playerId: userId, lastCardData: lastCardData,
                      player: player, firebaseMessaging: _firebaseMessaging, fieldPlayers: fieldPlayers,))
              );
              await callReadyPlayer.call({"roomId": roomId});
              break;
            case("Team Invation Accepted"):
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => LoadingScreen())
              );
              break;
            case("Team Invitation"):
              var senderName = message["data"]["senderName"];
              var senderId = message["data"]["senderId"];

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                        senderName.toString() + " wants to play a Multiplayer Game with you. Join him?"
                    ),

                    content: Container(
                      width: mediaQueryData.size.height * 0.5,
                      height: mediaQueryData.size.width * 0.2,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            NiceButton(
                              width: mediaQueryData.size.width * 0.2,
//                              width: 100,
                              elevation: 1.0,
                              radius: 52.0,
                              background: Colors.lightGreenAccent,
                              textColor: Colors.black,
                              text: "Yes",
                              onPressed: () {
                                Navigator.pop(context);
                                var data = {
                                  "receiverId": senderId,
                                  "senderName": ProfileData.name
                                };

                                callAcceptTeamInvitation.call(data);

                                data = {
                                  "gameType": "TeamGame",
                                  "firstPlayerId": "11",
                                  "firstPlayerToken": userToken,
                                  "secondPlayerId": senderId
                                };

                                callFindRoom.call(data);
                              },
                            ),
                            NiceButton(
                              width: mediaQueryData.size.width * 0.2,
//                              width: 100,
                              elevation: 1.0,
                              radius: 52.0,
                              background: Colors.lightGreenAccent,
                              textColor: Colors.black,
                              text: "No",
                              onPressed: () {
                                Navigator.pop(context);
                                //TODO: send msg that this user declined
                              },
                            )
                          ],
                        ),
                      ),
                    )
                  );
                }
              );

              break;
            case ("Profile Data"):
              ProfileData.name = message["data"]["userName"];
              ProfileData.singleGameWins = message["data"]["singleGameWins"];
              ProfileData.teamGameWins = message["data"]["teamGameWins"];
              ProfileData.updated.value = !ProfileData.updated.value;
              break;
          }

          return;
        }
    );
    _firebaseMessaging.getToken().then((token) async {
      userToken = token;

      var data = {
        "userToken": userToken,
        "userId": userId
      };

      var received = (await callGetProfileData.call(data)).data;

      ProfileData.name = received["userName"];
      ProfileData.singleGameWins = received["singleGameWins"];
      ProfileData.teamGameWins = received["teamGameWins"];
      ProfileData.updated.value = !ProfileData.updated.value;
    });
  }

  List<String> getPlayerNames(var playerNames) {
    var playerNamesSplitted = playerNames.toString().split(",");
    int playerTurnIndex = 0;

    for(int i = 0; i < playerNamesSplitted.length; i++) {
      if(playerNamesSplitted[i] == playerName) playerTurnIndex = i;
    }

    List<String> result = new List<String>();

    switch(playerTurnIndex) {
      case(0):
        for(int i = 1; i < playerNamesSplitted.length; i++) {
          result.add(playerNamesSplitted[i]);
        }
        break;
      case(1):
        for(int i = 2; i < playerNamesSplitted.length; i++) {
          result.add(playerNamesSplitted[i]);
        }
        result.add(playerNamesSplitted[0]);
        break;
      case(2):
        result.add(playerNamesSplitted[3]);
        for(int i = 0; i < playerTurnIndex; i++) {
          result.add(playerNamesSplitted[i]);
        }
        break;
      case(3):
        for(int i = 0; i < playerTurnIndex; i++) {
          result.add(playerNamesSplitted[i]);
        }
        break;
    }

    return result;
  }

  void showToast(var toastMsg){
    Fluttertoast.showToast(
        msg: toastMsg.toString(),
        timeInSecForIos: 10,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT
    );
  }

  var mediaQueryData;

  @override
  Widget build(BuildContext context) {

    var theme = Theme.of(context);

    print("First Once");

    mediaQueryData = MediaQuery.of(context);
    final iconButtonMargin = 10.0;

    return SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  //color: Colors.cyanAccent,
                  //height: mediaQueryData.size.height/2,
                  margin: EdgeInsets.all(iconButtonMargin),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios),
                    color: Colors.black,
                    onPressed: () {
                      setState(() {
                        if(currentIndex.value == 0) {
                          currentIndex.value = types.length - 1;
                        }
                        else {
                          currentIndex.value--;
                        }
                        currGT.value = types[currentIndex.value];
                      });
                    },
                  ),
                ),
                ValueListenableBuilder<gameType> (
                  valueListenable: currGT,
                  builder: (context, currentIndex, Widget child) {
                    return Container(
                      height: mediaQueryData.size.height/2,
                      width: mediaQueryData.size.width * 0.6,
                      //color: Colors.blue,
                      child: Container (
                        decoration: BoxDecoration(
                          border: new Border.all(
                            color: theme.primaryColor,
                            width: 5.0,
                            style: BorderStyle.solid
                          ),
                          borderRadius: new BorderRadius.all(new Radius.circular(10.0))
                        ),
                        //color: Colors.blue,
                        child: Container(color: theme.primaryColor, child: Center(child: gameTypeWindow[currGT.value]))
                      ),
                    );
                  }
                ),
                Container(
                  //color: Colors.cyanAccent,
                  //height: mediaQueryData.size.height/2,
                  margin: EdgeInsets.all(iconButtonMargin),
                  child: IconButton(
                    icon: Icon(Icons.arrow_forward_ios),
                    color: Colors.black,
                    onPressed: () {
                      setState(() {
                        if(currentIndex.value == types.length - 1) {
                          currentIndex.value = 0;
                        }
                        else {
                          currentIndex.value++;
                        }
                        currGT.value = types[currentIndex.value];
                      });
                    },
                  ),
                ),
              ],
            ),
            Container(
              height: mediaQueryData.size.height * 0.03,
            ),
            Container(
              //width and height
//              width: mediaQueryData.size.width * 0.4,
//              height: mediaQueryData.size.height * 0.15,
              child: NiceButton(
                width: mediaQueryData.size.width * 0.4,
                elevation: 1.0,
                radius: 52.0,
                background: theme.buttonColor,
//                background: theme.buttonColor,
                textColor: Colors.black,
                text: "Play",
                onPressed: () async {
                  //TODO: whether the selectedGameType it open a InvitationMenu or navigates to a GameRoom
                  if(!playBtnCalled) {
                    switch (currGT.value) {
                      case(gameType.singleGame) :
                        {
                          playBtnCalled = true;
                          ///Call the findRoom function
                          var data = {
                            "playerId": userId,
                            "gameType": "SingleGame",
                            "playerToken": userToken
                          };

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => LoadingScreen())
                          );
                          print("Loading screen");

                          playBtnCalled = false;

                          await callFindRoom(data);

                          break;
                        }
                      case(gameType.teamGame) :
                        {

                          var result = (await callGetOnlineFriends.call({"userId": userId})).data;

                          List<Widget> friends = new List<Widget>();

                          for(int i = 0; i < result.length; i++) {
                            friends.add(drawFriendToInvite(result[i]["name"], userId, mediaQueryData.size.width * 0.5, mediaQueryData.size.height * 0.2));
                          }

                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Center(child: Text("Invite a friend")),
                                content: Container(
                                  width: mediaQueryData.size.width * 0.5,
                                  height: mediaQueryData.size.height * 0.6,
                                  child: ListView(
                                    scrollDirection: Axis.vertical,
                                    children: friends
                                  ),
                                ),
                              );
                            },
                          );
                          break;
                        }
                      default :
                        {
                          break;
                        }
                    }
                  }
                },
              ),
            )
          ]
        ),
    );
  }

  Widget drawFriendToInvite(String username, String id, double width, double heigth) {
    return Container(
      width: width,
      height: heigth,
      child: Row(
        children: <Widget>[
          Container(
            width: width * 0.8,
            child: Text(
              username
            ),
          ),
          Container(
            width: width * 0.2,
            child: IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                var temp = {
                  "senderName": ProfileData.name,
                  "senderId": userId,
                  "friendId": id
                };

                callSendTeamGameInvitation.call(temp);

                showToast("Invitation sent");
              },
            ),
          )
        ],
      ),
    );
  }
}
