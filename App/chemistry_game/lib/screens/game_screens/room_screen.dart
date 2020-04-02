import 'dart:async';

import 'package:badges/badges.dart';
import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/fieldPlayer.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:chemistry_game/screens/game_screens/summary_screen.dart';
import 'package:chemistry_game/screens/home/home.dart';
import 'package:chemistry_game/screens/home/main_screen.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:nice_button/nice_button.dart';

// ignore: must_be_immutable
class BuildRoomScreen extends StatefulWidget {

  FirebaseMessaging firebaseMessaging;
  final String roomId;
  final String playerId;
  final ElementCard lastCardData;
  final playerName;
  final fieldPlayers;
  Player player;
  BuildRoomScreen({this.roomId, this.playerId, this.fieldPlayers,
                    this.lastCardData, this.playerName, this.player, this.firebaseMessaging});

  static String inGameMessages = "";

  @override
  _BuildRoomScreenState createState() =>
      _BuildRoomScreenState(roomId: roomId, playerId: playerId,
      lastCardData: lastCardData, playerName: playerName, player: player, firebaseMessaging: firebaseMessaging,
      fieldPlayers: this.fieldPlayers);
}

class _BuildRoomScreenState extends State<BuildRoomScreen> {

  FirebaseMessaging firebaseMessaging;
  ElementCard lastCardData;
  String playerId;
  String roomId;
  var playerName;
  List<FieldPlayer> fieldPlayers = new List<FieldPlayer>();
  Player player;

  _BuildRoomScreenState({this.roomId, this.playerId, this.lastCardData,
                          this.playerName, this.player, this.firebaseMessaging, this.fieldPlayers});

  ValueNotifier<int> listViewStartingIndex = ValueNotifier<int>(0);
  ValueNotifier<BuildMenuShowingCardsType> buildMenuShowingCardsType =
                          new ValueNotifier<BuildMenuShowingCardsType>(BuildMenuShowingCardsType.ElementCards);

  ValueNotifier<int> elementCardsInBuildMenuStartingIndex = new ValueNotifier<int>(0);
  ValueNotifier<int> compoundCardsInBuildMenuStartingIndex = new ValueNotifier<int>(0);
  int shownElementCardsInBuildMenu = 8;
  int shownCompoundCardsInBuildMenu = 8;
  var points = new ValueNotifier<int>(0);

  bool showElementCards = true;
  bool calledFunction = false;

  Reaction currReaction = Reaction();

  List<String> textMessages = BuildRoomScreen.inGameMessages.split(",");
  List<PopupMenuItem> textMessagesWidgets = new List<PopupMenuItem>();

  bool completeReactionCalled = false;
  String chatMsgSender = "";
  var chatMsg = new ValueNotifier("");

  final GlobalKey _menuKey = new GlobalKey();

  bool unseenElementCards = false;

  final HttpsCallable callPlaceCard = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'placeCard',
  );

  final HttpsCallable callCompleteReaction = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'completeReaction',
  );

  final HttpsCallable callGetDeckCard = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'getDeckCard',
  );

  final HttpsCallable callSendChatMsgToEveryone = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'sendChatMsgToEveryone',
  );

  final HttpsCallable callAddLeftPlayer = CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'addLeftPlayer',
  );

  Timer _timer;
  int _start = 10;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
          (Timer timer) => setState(
            () {
          if (_start < 1) {
            timer.cancel();
          } else {
            _start = _start - 1;
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String playerToken;
  var toastMsg;
  var cardToRemove = new ElementCard();
  var playerOnTurn;
  var playerOnTurnName = "";

  @override
  void initState() {
    super.initState();
    firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          var data = message["notification"];
          print("Message received in room screen: $data");

          switch(data["title"])
          {
            case("Start"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              break;
            case("Single Game Finished"):
              print("Single Game Finished");
              showToast("Game finished");

              if(message.containsKey("data")) {
                var firstPlace = message["data"]["firstPlace"];
                var secondPlace = message["data"]["secondPlace"];
                var thirdPlace = message["data"]["thirdPlace"];
                var fourthPlace = message["data"]["fourthPlace"];

                if(firstPlace == null) break;
                else {
                  List<String> places = [
                    firstPlace.toString(),
                    secondPlace.toString(),
                    thirdPlace.toString(),
                    fourthPlace.toString()
                  ];
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>
                      SummaryScreen(places, GameType.singleGame)
                    ));
                }
              }
              break;
            case("Team Game Finished"):
              print("Team Game Finished");
              showToast("Game finished");

              if(message.containsKey("data")) {
                var firstPlace = message["data"]["player1"];
                var secondPlace = message["data"]["player2"];
                var thirdPlace = message["data"]["player3"];
                var fourthPlace = message["data"]["player4"];

                if(firstPlace == null) break;
                else {
                  List<String> places = [
                    firstPlace.toString(),
                    secondPlace.toString(),
                    thirdPlace.toString(),
                    fourthPlace.toString()
                  ];
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) =>
                          SummaryScreen(places, GameType.teamGame)
                      ));
                }
              }
              break;
            case("Points Updated"):
              points.value = int.parse(message["data"]["pointsToAdd"]);
              break;
            case("Placed Card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              player.removeElementCard(cardToRemove.name, cardToRemove);
              calledFunction = false;
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });
              break;
            case("Not Your Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              calledFunction = false;
              break;
            case("Incorrect card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              calledFunction = false;
              break;
            case("Player Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);

              if(_timer != null) _timer.cancel();
              _start = 15;
              startTimer();

              playerOnTurn = message["data"]["playerId"];
              playerOnTurnName = message["data"]["playerName"];
              break;
            case("Missed Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              var currPlayerId = message["data"]["playerId"];

              if(currPlayerId == playerId) {
                var cardToAddString = message["data"]["cardToAdd"];
                player.addElementCard(ElementCard.fromString(cardToAddString.toString()));
                setState(() {
                  listViewStartingIndex = listViewStartingIndex;
                });
              }
              break;
            case("New Last Card"):
              var newLastCard = message["data"]["newLastCard"];
              var splitted = newLastCard.toString().split(",");
              setState(() {
                lastCardData = ElementCard(name: splitted[0], group: splitted[1], period: int.parse(splitted[2]));
              });
              break;
            case("Complete Reaction Failed"):
              toastMsg = message["notification"]["body"];
              currReaction.clear();
              showToast(toastMsg);
              completeReactionCalled = false;
              break;
            case("Cannot Place Card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              calledFunction = false;
              break;
            case("Receive Deck Card"):
              var cardData = message["data"]["cardToGiveData"];

              player.addElementCard(ElementCard.fromString(cardData.toString()));
              calledFunction = false;
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });
              break;
            case("You Finished"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);

              player.finishedCards = true;
              break;
            case("Chat Msg"):
              var msgSender = message["data"]["sender"];
              var msg = message["data"]["msg"];

              for(int i = 0; i < fieldPlayers.length; i++) {
                if(fieldPlayers[i].name == msgSender) {
                  fieldPlayers[i].lastMessage = msg.toString();
                  break;
                }
              }
              break;
            case("Empty Side"):
              toastMsg = message["notification"]["body"];
              currReaction.clear();
              completeReactionCalled = false;
              showToast(toastMsg);
              break;
            case("Complete Reaction Successed"):
              toastMsg = message["notification"]["body"];
              var cardToAdd = "";

              currReaction.leftSideCards.values.forEach((card) {
                if(card is ElementCard)
                {
                  player.removeElementCard(card.name, card);
                }
                else
                {
                  player.removeCompoundCard(card);
                }
              });

              currReaction.rightSideCards.values.forEach((card) {
                if(card is ElementCard)
                {
                  player.removeElementCard(card.name, card);
                }
                else
                {
                  player.removeCompoundCard(card);
                }
              });

              currReaction.clear();

              showToast(toastMsg);

              setState(() {
                if (buildMenuShowingCardsType.value ==
                    BuildMenuShowingCardsType.ElementCards) {
                  buildMenuShowingCardsType.value =
                      BuildMenuShowingCardsType.CompoundCards;
                }
                else {
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ElementCards;
                }
              });
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });

              if(message["data"].containsKey("cardToAdd"))
              {
                print("Card to add");
                cardToAdd = message["data"]["cardToAdd"];

                if(cardToAdd.contains(","))
                {
                  player.addElementCard(ElementCard.fromString(cardToAdd.toString()));
                }
                else
                {
                  player.addCompoundCard(CompoundCard.fromString(cardToAdd));
                }
              }
              setState(() {
                buildMenuShowingCardsType = buildMenuShowingCardsType;
              });

              completeReactionCalled = false;

              break;
          }

          return;
        }
    );
    firebaseMessaging.getToken().then((token) {
      playerToken = token;
    });
  }

  void showToast(var toastMsg){
    Fluttertoast.showToast(
        msg: toastMsg.toString(),
        timeInSecForIos: 10, //TODO: set it back to 1/2 sec
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_SHORT
    );
  }

  void showTopToast(var toastMsg){
    Fluttertoast.showToast(
        msg: toastMsg.toString(),
        timeInSecForIos: 10, //TODO: set it back to 1/2 sec
        gravity: ToastGravity.TOP,
        toastLength: Toast.LENGTH_SHORT
    );
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    textMessagesWidgets.clear();
    textMessages.forEach((text) {
      textMessagesWidgets.add(
        new PopupMenuItem<String>(
          child: Text(text),
          value: text,
        )
      );
    });

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    List<Draggable> elementCards = List<Draggable>();

    player.getElementCards().forEach( (e) => elementCards.add(e.drawDraggableElementCard(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2)));

    ListView getElementCards(int startingIndex) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: elementCards.sublist(startingIndex,
            startingIndex+6 > player.getElementCards().length ? player.getElementCards().length : startingIndex+6)
      );
    }

    Future<bool> _onWillPop() async {
      return showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Container(
              child: AlertDialog(
                  title: Center(child: Text("Are you sure you want to leave the room?")),
                  content: Container(
                    width: mediaQueryWidth * 0.5,
                    height: mediaQueryHeight * 0.2,
                    child: Center(
                      child: Row(
                        children: <Widget>[
                          NiceButton(
                            width: mediaQueryWidth * 0.2,
                            elevation: 1.0,
                            radius: 52.0,
                            background: primaryGreen,
                            textColor: Colors.black,
                            text: "Yes",
                            onPressed: () {
                              var data = {
                                "playerId": playerId,
                                "roomId": roomId
                              };
                              callAddLeftPlayer.call(data);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => HomeScreen())
                              );
                            },
                          ),
                          NiceButton(
                            width: mediaQueryWidth * 0.2,
                            elevation: 1.0,
                            radius: 52.0,
                            background: primaryGreen,
                            textColor: Colors.black,
                            text: "No",
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          )
                        ],
                      ),
                    ),
                  )
              ),
            );
          }
      ) ?? false;
    }

    Widget drawLeftSide() {
      return Column(
        children: <Widget>[
          Container(
            width: mediaQueryWidth * 0.20,
            height: mediaQueryHeight * 0.25,
            child: Row(
              children: <Widget>[
                Container(
                  width: mediaQueryWidth * 0.10,
                  child: PopupMenuButton(
                    key: _menuKey,
                    child: RawMaterialButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0)
                      ),
                      child: Icon(Icons.message, color: primaryGreen,),
                      onPressed: () {
                        dynamic state = _menuKey.currentState;
                        state.showButtonMenu();
                      },
                    ),
                    itemBuilder: (_) => textMessagesWidgets,
                    onSelected: (value) {
                      var data = {
                        "msg": value,
                        "senderName": player.name, ///TODO: change it to player.name
                        "senderId": player.id
                      };

                      callSendChatMsgToEveryone(data);
                    },
                  ),

                  alignment: Alignment.topCenter,
                ),
                Container(
                  width: mediaQueryWidth * 0.10,
                  child: new LayoutBuilder(builder: (context, constraint) {
                    return new Text(
                        _start.toString(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: constraint.biggest.height/2));
                  }),
                  alignment: Alignment.center,
                )
              ],
            ),
          ),

          Row(
            children: <Widget>[
              Container(
                  width: mediaQueryWidth * 0.10,
                  height: mediaQueryHeight * 0.50,
                  color: secondaryYellow,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                          Icons.person
                      ),
                      Text(
                        fieldPlayers[2].name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Text(
                          "Cards: " + fieldPlayers[2].cardsNumber.toString()
                      ),
                      Row(
                        children: <Widget>[
                          Icon(Icons.message),
                          Flexible(
                            child: Text(
                                ": " + fieldPlayers[2].lastMessage
                            ),
                          )
                        ],
                      )
                    ],
                  )
              ),
              Container(
                width: mediaQueryWidth * 0.10,
                height: mediaQueryHeight * 0.50,
              ),
            ],
          ),

          Container(
            width: mediaQueryWidth * 0.20,
            height: mediaQueryHeight * 0.25,
            child: ValueListenableBuilder(
              valueListenable: listViewStartingIndex,
              builder: (BuildContext context, int value, Widget child) {
                if (!(listViewStartingIndex.value - 6 < 0)) {
                  return RawMaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Icon(Icons.arrow_back, color: primaryGreen),
                    onPressed: () {
                      setState(() {
                        listViewStartingIndex.value -= 6;
                      });
                    },
                  );
                }
                else {
                  return Container();
                }
              },
              child: RawMaterialButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                ),
                child: Icon(Icons.arrow_back, color: primaryGreen),
                onPressed: () {
                  setState(() {
                    if(!(listViewStartingIndex.value - 6 < 0)) {
                      listViewStartingIndex.value -= 6;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    Widget drawMiddleSide() {
      return Column(
          children: <Widget> [
            Container(
              height: mediaQueryHeight * 0.1,
              width: mediaQueryWidth * 0.6,
              color: secondaryPink,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                      Icons.person
                  ),

                  Text(
                    fieldPlayers[1].name + " ",
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  Text(
                      "Cards: " + fieldPlayers[1].cardsNumber.toString()
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.message),
                      Flexible(
                        child: Text(
                            ": " + fieldPlayers[1].lastMessage
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            Container(
              height: mediaQueryHeight * 0.15,
              width: mediaQueryWidth * 0.6,
              child: Center(
                child: Text(
                    playerOnTurnName + " is on turn"
                ),
              ),
            ),

            Container(
              width: mediaQueryWidth * 0.6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                children: <Widget>[
                  //Deck
                  Container(
                    height: mediaQueryHeight * 0.4,
                    width: mediaQueryWidth * 0.15,
                    child: RaisedButton(
                      child: Center(child: Text("Deck")),
                      onPressed: () async {

                        if(!calledFunction && playerOnTurn == playerId) {
                          calledFunction = true;
                          showToast("wait...");
                          var cardData = (await callGetDeckCard({"playerId": playerId, "roomId": roomId, "playerToken": playerToken})).data;

                          if(cardData == false) {
                            showToast("It is not your turn!");
                            calledFunction = false;
                            return;
                          }

                          player.addElementCard(ElementCard.fromString(cardData.toString()));
                          calledFunction = false;
                          setState(() {
                            listViewStartingIndex = listViewStartingIndex;
                          });
                        }
                        else
                        {
                          showToast("You cannot get deck card now");
                        }

                      },
                    ),
                  ),

                  //Last Card
                  drawLastCardDragTarget(mediaQueryWidth * 0.15, mediaQueryHeight * 0.4),

                  //Build Menu
                  Container(
                    height: mediaQueryHeight * 0.4,
                    width: mediaQueryWidth * 0.15,
                    child: RaisedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Center(child: Text("Build Menu")),
                                content: Container(
                                  width: mediaQueryWidth * 0.8,
                                  height: mediaQueryHeight * 0.8,
                                  decoration: BoxDecoration( //TODO: Make it responsive
                                      border: Border.all(
                                        width: mediaQueryHeight * 0.0025,
                                        color: Colors.black,
                                      )
                                  ),
                                  child: createBuildMenuContent(mediaQueryWidth * 0.8 - mediaQueryHeight * 0.01, mediaQueryHeight * 0.64),
                                ),
                              );
                            }
                        );
                      },
                      child: Text("Build Menu"),
                    ),
                  )

                ],
              ),
            ),

            Container(
              height: mediaQueryHeight * 0.15,
              width: mediaQueryWidth * 0.6,
            ),

            Container(
                height: mediaQueryHeight * 0.2,
                width: mediaQueryWidth * 0.6,
                child: ValueListenableBuilder(
                  valueListenable: listViewStartingIndex,
                  builder: (BuildContext context, int value, Widget child) {
                    return getElementCards(listViewStartingIndex.value);
                  },
                  child: getElementCards(listViewStartingIndex.value),
                )
            )
          ]
      );
    }

    Widget drawRightSide() {
      return Column(
        children: <Widget>[
          Container(
              width: mediaQueryWidth * 0.20,
              height: mediaQueryHeight * 0.25,
              child: Row(
                children: <Widget>[
                  Container(
                    width: mediaQueryWidth * 0.10,
                    child: Center(
                      child: Text(
                          "points: " + points.value.toString()
                      ),
                    ),
                  ),
                  Container(
                    width: mediaQueryWidth * 0.10,
                    child: RawMaterialButton(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                      child: Icon(Icons.clear),
                      onPressed: () {
                        _onWillPop();
                      },
                    ),
                    alignment: Alignment.topCenter,
                  ),
                ],
              )
          ),

          Row(
            children: <Widget>[
              Container(
                width: mediaQueryWidth * 0.10,
                height: mediaQueryHeight * 0.50,
              ),
              Container(
                width: mediaQueryWidth * 0.10,
                height: mediaQueryHeight * 0.50,
                color: primaryGreen,//Colors.green,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                        Icons.person
                    ),
                    Text(
                      fieldPlayers[0].name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    Text(
                        "Cards: " + fieldPlayers[0].cardsNumber.toString()
                    ),
                    Row(
                      children: <Widget>[
                        Icon(Icons.message),
                        Flexible(
                          child: Text(
                              ": " + fieldPlayers[0].lastMessage
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          Container(
            width: mediaQueryWidth * 0.20,
            height: mediaQueryHeight * 0.25,
            child: ValueListenableBuilder(
              valueListenable: listViewStartingIndex,
              builder: (BuildContext context, int value, Widget child) {
                if(!(listViewStartingIndex.value + 6 >= player.getElementCards().length)) {
                  return RawMaterialButton(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                    ),
                    child: Icon(Icons.arrow_forward, color: primaryGreen),
                    onPressed: () {
                      setState(() {
                        listViewStartingIndex.value += 6;
                      });
                    },
                  );
                }
                else {
                  return Container();
                }
              },
              child: RawMaterialButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                ),
                child: Icon(Icons.arrow_forward, color: primaryGreen),
                onPressed: () {
                  setState(() {
                    if(!(listViewStartingIndex.value + 6 >= player.getElementCards().length)) {
                      listViewStartingIndex.value += 6;
                    }
                  });
                },
              ),
            ),
          ),
        ],
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: <Widget>[

            drawLeftSide(),

            drawMiddleSide(),

            drawRightSide()
          ],
        ),
      ),
    );
  }

  Widget createBuildMenuContent(double width, double height) {

    return Container(
      width: width,
      height: height,

      child: Column(
        children: <Widget>[
          drawReactionRow(width, height * 0.5, currReaction),
          drawCardsArea(width, height * 0.5),
        ],
      )

    );
  }

  Widget drawCardsArea(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          drawCardTypeButtons(width * 0.2, height),
          drawCardsAvailable(width * 0.75, height),
        ],
      ),
    );
  }

  Widget drawCardTypeButtons(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Badge(
                badgeContent: Text('3'),
                child: Container(
                  child: Text(
                      "Elements"
                  ),
                ),
              ),
              onPressed: () {
                setState(() {
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ElementCards;
                });
              },
            ),
          ),
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Text("Compounds"),
              onPressed: () {
                setState(() {
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.CompoundCards;
                });
              },
            ),
          ),
          Container(
            height: height * 0.3,
            child: RaisedButton(
              child: Text("Accelerations"),
              onPressed: () {
                showToast("We work on Accelerations");
                //TODO: set to AccelerationCards
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget drawCardsAvailable(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: ValueListenableBuilder(
        builder: (BuildContext context, BuildMenuShowingCardsType value , Widget child) {
          List<Widget> cards = new List<Widget>();

          switch(buildMenuShowingCardsType.value) {
            case (BuildMenuShowingCardsType.ElementCards):
              player.getElementCards().forEach((card) => cards.add(card.drawDraggableCard(width * 0.1, height)));
              return Row(
                children: <Widget>[
                  drawBuildMenuLeftArrow(buildMenuShowingCardsType.value, width * 0.1),
                  ValueListenableBuilder(
                    valueListenable: elementCardsInBuildMenuStartingIndex,
                    builder: (BuildContext context, int value, Widget child) {
                      return Row(
                        children: cards.sublist(elementCardsInBuildMenuStartingIndex.value,
                            ((elementCardsInBuildMenuStartingIndex.value + shownElementCardsInBuildMenu) <= player.getElementCards().length ?
                            elementCardsInBuildMenuStartingIndex.value + shownElementCardsInBuildMenu : player.getElementCards().length)),
                      );
                    },
                    child: Container(),
                  ),
                  drawBuildMenuRightArrow(buildMenuShowingCardsType.value, width * 0.1),
                ],
              );

              break;
            case (BuildMenuShowingCardsType.CompoundCards):
              player.compoundCards.forEach((card) => cards.add(card.drawDraggable(width * 0.1, height)));
//              cards.sublist(compoundCardsInBuildMenuStartingIndex.value,
//                  (compoundCardsInBuildMenuStartingIndex.value + shownCompoundCardsInBuildMenu - 1 <= player.compoundCards.length ?
//                      compoundCardsInBuildMenuStartingIndex.value + shownCompoundCardsInBuildMenu - 1 : player.compoundCards.length));

              return Row(
                children: <Widget>[
                  drawBuildMenuLeftArrow(buildMenuShowingCardsType.value, width * 0.1),
                  ValueListenableBuilder(
                    valueListenable: compoundCardsInBuildMenuStartingIndex,
                    builder: (BuildContext context, int value, Widget child) {
                      return Row(
                        children: cards.sublist(compoundCardsInBuildMenuStartingIndex.value,
                            ((compoundCardsInBuildMenuStartingIndex.value + shownCompoundCardsInBuildMenu) <= player.compoundCards.length ?
                            compoundCardsInBuildMenuStartingIndex.value + shownCompoundCardsInBuildMenu : player.compoundCards.length)),
                      );
                    },
                    child: Container(),
                  ),
                  drawBuildMenuRightArrow(buildMenuShowingCardsType.value, width * 0.1),
                ],
              );

              break;
          /*case (BuildMenuShowingCardsType.AccelerationCards):
            break;*/
            default: {
              print("Error, invalid type");
              return Container(

              );
            }
          }
        },
        child: Container(
          width: width,
          height: height,
          color: Colors.red,
        ),
        valueListenable: buildMenuShowingCardsType,
      ),
    );
  }

  Widget drawBuildMenuLeftArrow(BuildMenuShowingCardsType buildMenuShowingCardsType, double width) {
    switch(buildMenuShowingCardsType) {
      case (BuildMenuShowingCardsType.ElementCards):
        return ValueListenableBuilder(
          valueListenable: elementCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if(value - shownElementCardsInBuildMenu >= 0) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryGreen),
                  onPressed: () {
                    setState(() {
                      elementCardsInBuildMenuStartingIndex.value -= shownElementCardsInBuildMenu;
                    });
                  },
                ),
              );
            }
            else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      case(BuildMenuShowingCardsType.CompoundCards):
        return ValueListenableBuilder(
          valueListenable: compoundCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if(value - shownCompoundCardsInBuildMenu >= 0) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: primaryGreen),
                  onPressed: () {
                    setState(() {
                      compoundCardsInBuildMenuStartingIndex.value -= shownCompoundCardsInBuildMenu;
                    });
                  },
                ),
              );
            }
            else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      default:
        return Container();
    }
  }

  Widget drawBuildMenuRightArrow(BuildMenuShowingCardsType buildMenuShowingCardsType, double width) {
    switch(buildMenuShowingCardsType) {
      case (BuildMenuShowingCardsType.ElementCards):
        return ValueListenableBuilder(
          valueListenable: elementCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if(value + shownElementCardsInBuildMenu < player.getElementCards().length) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: primaryGreen),
                  onPressed: () {
                    setState(() {
                      elementCardsInBuildMenuStartingIndex.value += shownElementCardsInBuildMenu;
                    });
                  },
                ),
              );
            }
            else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      case(BuildMenuShowingCardsType.CompoundCards):
        return ValueListenableBuilder(
          valueListenable: compoundCardsInBuildMenuStartingIndex,
          builder: (BuildContext context, int value, Widget child) {
            if(value + shownCompoundCardsInBuildMenu < player.compoundCards.length) {
              return Container(
                width: width,
                child: IconButton(
                  icon: Icon(Icons.arrow_forward, color: primaryGreen),
                  onPressed: () {
                    setState(() {
                      compoundCardsInBuildMenuStartingIndex.value += shownCompoundCardsInBuildMenu;
                    });
                  },
                ),
              );
            }
            else {
              return Container(
                width: 0,
                height: 0,
              );
            }
          },
          child: Container(),
        );
        break;
      default:
        return Container();
    }
  }

//  void showSettingsDialog(double width, double height) {
//    showDialog(
//      context: context,
//      barrierDismissible: true,
//      builder: (BuildContext context) {
//        return AlertDialog(
//          title: Center(child: Text("Settings")),
//          content: Container(
//            width: width,
//            height: height,
//            decoration: BoxDecoration( //TODO: Make it responsible
//                border: Border.all(
//                  width: 0.2,
//                  color: Colors.black,
//                )
//            ),
//            child: settingsOptions(width, height)
//          ),
//        );
//      }
//    );
//  }

  Widget leaveButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: RaisedButton(
        child: Center(
          child: Text(
            "Leave"
          ),
        ),
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.push(
            context, MaterialPageRoute(builder: (context) => HomeScreen())
          );
        },
      ),
    );
  }

  Container settingsOptions(double width, double height) {
    return Container(
      child: ListView(
        children: <Widget>[
          leaveButton(width, height * 0.4),
        ],
      )
    );
  }

  Widget drawReactionRow(double width, double height, Reaction reaction) {
    return Container(
      width: width,
      height: height,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                drawCompleteButton(width, height),
                reaction.draw(width * 0.8, height),
              ],
            ),
          ),
          drawDeleteButton(width * 0.1, height * 0.7, reaction)
        ]
      ),
    );
  }

  Widget drawCompleteButton(double width, double height) {
    return ValueListenableBuilder(
      valueListenable: currReaction.exists,
      builder: (BuildContext context, bool value, Widget child) {
        if(value) {
          return child;
        }
        else {
          return Container(
            width: 0,
            height: 0,
          );
        }
      },
      child: IconButton(
        icon: Icon(Icons.check),
        color: Colors.green,
        onPressed: () async {

          if(player.finishedCards) {
            showToast("You have already finished");
            return;
          }

          if(completeReactionCalled) {
            showToast("Wait until the check is complete!");
            return;
          }
          else {
            completeReactionCalled = true;
          }

          List<Map<String, String>> leftCards = new List<Map<String, String>>();
          List<Map<String, String>> rightCards = new List<Map<String, String>>();

          currReaction.leftSideCards.values.forEach((card) {
            if(card != null)
            {
              leftCards.add({"name": card.name, "uuid": card.uuid});
            }
          });

          currReaction.rightSideCards.values.forEach((card) {
            if(card != null)
            {
              rightCards.add({"name": card.name, "uuid": card.uuid});
            }
          });

          var dataToSend = {
            "playerId": playerId,
            "playerToken": playerToken,
            "leftSideCards": leftCards,
            "rightSideCards": rightCards
          };
          showToast("wait...");
          await callCompleteReaction(dataToSend);
        },
      ),
    );
  }

  Widget drawDeleteButton(double width, double height, Reaction reaction) {
    return Container(
      width: width,
      height: height,
      child: ValueListenableBuilder(
        valueListenable: currReaction.exists,
        builder: (BuildContext context, bool value, Widget child) {
          if(value) {
            return child;
          }
          else {
            return Container(
              width: 0,
              height: 0,
            );
          }
        },
        child: IconButton(
          icon: Icon(Icons.delete_forever),
          color: Colors.red,
          onPressed: () {
            reaction.clear();
          },
        ),
      ),
    );
  }

  Widget drawLastCardDragTarget(double width, double height) {
    return DragTarget<ElementCard>(
      builder: (BuildContext context, List<card> incoming, rejected) {
        return lastCardData.draw(width, height);
      },

      onWillAccept: (data) => (data.group == lastCardData.group || data.period == lastCardData.period) && playerId == playerOnTurn && !calledFunction,

      onAccept: (data)
      async {
        calledFunction = true;
        showToast("wait");
        cardToRemove = data;
        var dataToSend = {
          "cardUuid": data.uuid,
          "playerId": playerId,
          "cardName": data.name.toString(),
          "roomId": roomId,
          "playerToken": playerToken,
        };

        dataToSend["cardName"] = data.name;

        var isPlaced = (await callPlaceCard.call(dataToSend)).data;

        if(isPlaced){
          toastMsg = "You have placed card successfully";
          showToast(toastMsg);
          player.removeElementCard(cardToRemove.name, cardToRemove);
          calledFunction = false;
          setState(() {
            listViewStartingIndex = listViewStartingIndex;
          });
        }
        else {
          toastMsg = "The group and the period do not coincide!";
          showToast(toastMsg);
          calledFunction = false;
        }
      },

      onLeave: (data) {

      },
    );
  }
}

enum BuildMenuShowingCardsType {
 ElementCards,
 CompoundCards
 ///AccelerationCards // in future
}