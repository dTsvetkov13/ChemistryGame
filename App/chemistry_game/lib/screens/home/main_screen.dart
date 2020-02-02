import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/screens/loading_screen.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
  //static int currentIndex = 0;
  //gameType selectedGameType = types[currentIndex.value];
  //gameType selectedGameType = types[currentIndex];

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

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String playerToken;

  var roomId;
  var lastCard;
  var playersNames;
  var playerName;

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

              callGetPlayerCards({"playerId": userId, "playerToken": playerToken});

              break;
            case("Join Room") :

              break;
            case("Player Cards") :
              var elementCards = message["data"]["elementCards"];
              var compoundCards = message["data"]["compoundCards"];
              playerName = message["data"]["playerName"];

              print("Element Cards: " + elementCards);
              print("Compound Cards: " + compoundCards);

              lastCard = lastCard.split(",");

              Player player = new Player(playerName, userId, elementCards, compoundCards);
              ElementCard lastCardData = new ElementCard(name: lastCard[0], group: lastCard[1], period: int.parse(lastCard[2]));



              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BuildRoomScreen(roomId: roomId, playerId: userId, lastCardData: lastCardData,
                      playersNames: playersNames, player: player, firebaseMessaging: _firebaseMessaging,))
              );
              await callReadyPlayer.call({"roomId": roomId});
              break;
          }

          return;
        }
    );
    _firebaseMessaging.getToken().then((token) {
      playerToken = token;
      print("Token : $playerToken");
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
        for(int i = playerTurnIndex + 1; i < playerNamesSplitted.length; i++) {
          result.add(playerNamesSplitted[i]);
        }
        break;
      case(1):
        for(int i = playerTurnIndex + 1; i < playerNamesSplitted.length; i++) {
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

  @override
  Widget build(BuildContext context) {

    print("First Once");

    final mediaQueryData = MediaQuery.of(context);
    final iconButtonMargin = 10.0;
    //print(selectedGameType);
    //print(gameTypeWindow[selectedGameType]);

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
                /*ValueListenableBuilder (
                  valueListenable: currentIndex,
                  child: Container(
                      height: mediaQueryData.size.height/2,
                      width: mediaQueryData.size.width * 0.6,
                      color: Colors.blue,
                      child: gameTypeWindow[selectedGameType]
                  ),
                ),*/
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
                            color: Colors.blue,
                            width: 5.0,
                            style: BorderStyle.solid
                          ),
                          borderRadius: new BorderRadius.all(new Radius.circular(10.0))
                        ),
                        //color: Colors.blue,
                        child: Container(color: Colors.blue, child: gameTypeWindow[currGT.value])
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
              //width and height
              width: mediaQueryData.size.width * 0.6,
              height: mediaQueryData.size.height * 0.07,
              child: RaisedButton(
                //shape:  ,
                child: Text(
                  "Play",
                ),
                onPressed: () async {
                  //TODO: whether the selectedGameType it open a InvitationMenu or navigates to a GameRoom
                  switch(currGT.value) {
                    case(gameType.singleGame) : {
                      ///Call the findRoom function
                      var data = {
                        "playerId": userId,
                        "gameType": "SingleGame",
                        "playerToken": playerToken
                      };

                      Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LoadingScreen())
                      );
                      print("Loading screen");

                      await callFindRoom(data);

                      break;
                    }
                    case(gameType.teamGame) : {
                      //Require a invitation
                      //Request teamGameRoom with a parther
                      //Get the id of the room
                      //Navigate to a room
                      break;
                    }
                    default : {
                      break;
                    }
                  }
                },
              ),
            )
          ]
        ),
    );
  }
}
