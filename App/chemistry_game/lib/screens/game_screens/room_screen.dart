import 'dart:async';

import 'package:chemistry_game/classes/build_menu.dart';
import 'package:chemistry_game/classes/utils.dart';
import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/enums.dart';
import 'package:chemistry_game/models/room.dart';
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
import 'package:nice_button/nice_button.dart';
import 'package:chemistry_game/models/remote_config.dart';

// ignore: must_be_immutable
class BuildRoomScreen extends StatefulWidget {
  FirebaseMessaging firebaseMessaging;

  BuildRoomScreen({this.firebaseMessaging, this.room});

  Room room;

  @override
  _BuildRoomScreenState createState() =>
      _BuildRoomScreenState(firebaseMessaging: firebaseMessaging, room: room);
}

class _BuildRoomScreenState extends State<BuildRoomScreen> {
  _BuildRoomScreenState({this.firebaseMessaging, this.room});

  Room room;
  FirebaseMessaging firebaseMessaging;
  BuildMenu buildMenu = new BuildMenu();

  ValueNotifier<int> listViewStartingIndex = ValueNotifier<int>(0);

  var points = new ValueNotifier<int>(0);

  bool calledFunction = false;

  List<String> textMessages = Config().getString("inGameMessages").split(",");
  List<PopupMenuItem> textMessagesWidgets = new List<PopupMenuItem>();

  String chatMsgSender = "";
  var chatMsg = new ValueNotifier("");

  final GlobalKey _menuKey = new GlobalKey();

  final HttpsCallable callPlaceCard =
      CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'placeCard',
  );

  final HttpsCallable callGetDeckCard =
      CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'getDeckCard',
  );

  final HttpsCallable callSendChatMsgToEveryone =
      CloudFunctions(region: "europe-west1").getHttpsCallable(
    functionName: 'sendChatMsgToEveryone',
  );

  final HttpsCallable callAddLeftPlayer =
      CloudFunctions(region: "europe-west1").getHttpsCallable(
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
    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      var data = message["notification"];
      print("Message received in room screen: $data");

      switch (data["title"]) {
        case ("Start"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          break;
        case ("Single Game Finished"):
          print("Single Game Finished");
          showToast("Game finished");

          if (message.containsKey("data")) {
            var firstPlace = message["data"]["firstPlace"];
            var secondPlace = message["data"]["secondPlace"];
            var thirdPlace = message["data"]["thirdPlace"];
            var fourthPlace = message["data"]["fourthPlace"];

            if (firstPlace == null)
              break;
            else {
              List<String> places = [
                firstPlace.toString(),
                secondPlace.toString(),
                thirdPlace.toString(),
                fourthPlace.toString()
              ];
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SummaryScreen(places, GameType.singleGame)));
            }
          }
          break;
        case ("Team Game Finished"):
          print("Team Game Finished");
          showToast("Game finished");

          if (message.containsKey("data")) {
            var firstPlace = message["data"]["player1"];
            var secondPlace = message["data"]["player2"];
            var thirdPlace = message["data"]["player3"];
            var fourthPlace = message["data"]["player4"];

            if (firstPlace == null)
              break;
            else {
              List<String> places = [
                firstPlace.toString(),
                secondPlace.toString(),
                thirdPlace.toString(),
                fourthPlace.toString()
              ];
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          SummaryScreen(places, GameType.teamGame)));
            }
          }
          break;
        case ("Points Updated"):
          points.value = int.parse(message["data"]["pointsToAdd"]);
          break;
        case ("Placed Card"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          room.player.removeElementCard(cardToRemove.name, cardToRemove);
          calledFunction = false;
          setState(() {
            listViewStartingIndex = listViewStartingIndex;
          });
          break;
        case ("Not Your Turn"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          calledFunction = false;
          break;
        case ("Incorrect card"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          calledFunction = false;
          break;
        case ("Player Turn"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);

          if (_timer != null) _timer.cancel();
          _start = 15;
          startTimer();

          playerOnTurn = message["data"]["playerId"];
          playerOnTurnName = message["data"]["playerName"];
          break;
        case ("Missed Turn"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          var currPlayerId = message["data"]["playerId"];

          if (currPlayerId == room.player.id) {
            var cardToAddString = message["data"]["cardToAdd"];
            room.player.addElementCard(
                ElementCard.fromString(cardToAddString.toString()));
            setState(() {
              listViewStartingIndex = listViewStartingIndex;
            });
          }
          break;
        case ("New Last Card"):
          var newLastCard = message["data"]["newLastCard"];
          var splitted = newLastCard.toString().split(",");
          setState(() {
            room.lastCard = ElementCard(
                name: splitted[0],
                group: splitted[1],
                period: int.parse(splitted[2]));
          });
          break;
        case ("Complete Reaction Failed"):
          toastMsg = message["notification"]["body"];
          buildMenu.currReaction.clear();
          showToast(toastMsg);
          buildMenu.completeReactionCalled = false;
          break;
        case ("Cannot Place Card"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);
          calledFunction = false;
          break;
        case ("Receive Deck Card"):
          var cardData = message["data"]["cardToGiveData"];

          room.player
              .addElementCard(ElementCard.fromString(cardData.toString()));
          calledFunction = false;
          setState(() {
            listViewStartingIndex = listViewStartingIndex;
          });

          buildMenu.updatedUnseenCards.value =
              !buildMenu.updatedUnseenCards.value;
          break;
        case ("You Finished"):
          toastMsg = message["notification"]["body"];
          showToast(toastMsg);

          room.player.finishedCards = true;
          break;
        case ("Chat Msg"):
          var msgSender = message["data"]["sender"];
          var msg = message["data"]["msg"];

          for (int i = 0; i < room.otherPlayers.length; i++) {
            if (room.otherPlayers[i].name == msgSender) {
              room.otherPlayers[i].lastMessage = msg.toString();
              break;
            }
          }
          break;
        case ("Empty Side"):
          toastMsg = message["notification"]["body"];
          buildMenu.currReaction.clear();
          buildMenu.completeReactionCalled = false;
          showToast(toastMsg);
          break;
        case ("Complete Reaction Successed"):
          toastMsg = message["notification"]["body"];
          var cardToAdd = "";

          buildMenu.currReaction.leftSideCards.values.forEach((card) {
            if (card is ElementCard) {
              room.player.removeElementCard(card.name, card);
            } else {
              room.player.removeCompoundCard(card);
            }
          });

          buildMenu.currReaction.rightSideCards.values.forEach((card) {
            if (card is ElementCard) {
              room.player.removeElementCard(card.name, card);
            } else {
              room.player.removeCompoundCard(card);
            }
          });

          buildMenu.currReaction.clear();

          showToast(toastMsg);

          if (buildMenu.buildMenuShowingCardsType.value ==
              BuildMenuShowingCardsType.ElementCards) {
            buildMenu.buildMenuShowingCardsType.value =
                BuildMenuShowingCardsType.CompoundCards;
          } else {
            buildMenu.buildMenuShowingCardsType.value =
                BuildMenuShowingCardsType.ElementCards;
          }

          listViewStartingIndex = listViewStartingIndex;

          if (message["data"].containsKey("cardToAdd")) {
            cardToAdd = message["data"]["cardToAdd"];

            if (cardToAdd.contains(",")) {
              room.player
                  .addElementCard(ElementCard.fromString(cardToAdd.toString()));
            } else {
              room.player.addCompoundCard(CompoundCard.fromString(cardToAdd));
            }
            buildMenu.updatedUnseenCards.value =
                !buildMenu.updatedUnseenCards.value;
          }

          buildMenu.buildMenuShowingCardsType =
              buildMenu.buildMenuShowingCardsType;

          buildMenu.completeReactionCalled = false;

          break;
      }

      return;
    });
    firebaseMessaging.getToken().then((token) {
      playerToken = token;
    });
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIOverlays([]);

    textMessagesWidgets.clear();
    textMessages.forEach((text) {
      textMessagesWidgets.add(new PopupMenuItem<String>(
        child: Text(text),
        value: text,
      ));
    });

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    List<Draggable> elementCards = List<Draggable>();

    room.player.getElementCards().forEach((e) => elementCards.add(
        e.drawDraggableElementCard(
            mediaQueryWidth * 0.1, mediaQueryHeight * 0.2)));

    ListView getElementCards(int startingIndex) {
      int endIndex = startingIndex + 6 > room.player.getElementCards().length
          ? room.player.getElementCards().length
          : startingIndex + 6;

      List<ElementCard> temp = room.player.getElementCards();

      for (int i = startingIndex; i < endIndex; i++) {
        room.player
            .setCardToSeen(temp.elementAt(i).uuid, temp.elementAt(i).name);
      }

      return ListView(
          scrollDirection: Axis.horizontal,
          children: elementCards.sublist(startingIndex, endIndex));
    }

    Future<bool> _onWillPop() async {
      return showDialog(
              context: context,
              barrierDismissible: true,
              builder: (BuildContext context) {
                return Container(
                  child: AlertDialog(
                      title: Center(
                          child:
                              Text("Are you sure you want to leave the room?")),
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
                                    "playerId": room.player.id,
                                    "roomId": room.roomId
                                  };
                                  callAddLeftPlayer.call(data);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => HomeScreen()));
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
                      )),
                );
              }) ??
          false;
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
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0)),
                      child: Icon(
                        Icons.message,
                        color: primaryGreen,
                      ),
                      onPressed: () {
                        dynamic state = _menuKey.currentState;
                        state.showButtonMenu();
                      },
                    ),
                    itemBuilder: (_) => textMessagesWidgets,
                    onSelected: (value) {
                      var data = {
                        "msg": value,
                        "senderName": room.player.name,
                        "senderId": room.player.id
                      };

                      callSendChatMsgToEveryone(data);
                    },
                  ),
                  alignment: Alignment.topCenter,
                ),
                Container(
                  width: mediaQueryWidth * 0.10,
                  child: new LayoutBuilder(builder: (context, constraint) {
                    return new Text(_start.toString(),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: constraint.biggest.height / 2));
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
                      Icon(Icons.person),
                      Text(
                        room.otherPlayers[2].name,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text("Cards: " +
                          room.otherPlayers[2].cardsNumber.toString()),
                      Row(
                        children: <Widget>[
                          Icon(Icons.message),
                          Flexible(
                            child:
                                Text(": " + room.otherPlayers[2].lastMessage),
                          )
                        ],
                      )
                    ],
                  )),
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
                      listViewStartingIndex.value -= 6;
                    },
                  );
                } else {
                  return Container();
                }
              },
              child: RawMaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                child: Icon(Icons.arrow_back, color: primaryGreen),
                onPressed: () {
                  if (!(listViewStartingIndex.value - 6 < 0)) {
                    listViewStartingIndex.value -= 6;
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    Widget drawMiddleSide() {
      return Column(children: <Widget>[
        Container(
          height: mediaQueryHeight * 0.1,
          width: mediaQueryWidth * 0.6,
          color: secondaryPink,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.person),
              Text(
                room.otherPlayers[1].name + " ",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text("Cards: " + room.otherPlayers[1].cardsNumber.toString()),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.message),
                  Flexible(
                    child: Text(": " + room.otherPlayers[1].lastMessage),
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
            child: Text(playerOnTurnName + " is on turn"),
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
                    if (!calledFunction && playerOnTurn == room.player.id) {
                      calledFunction = true;
                      showToast("wait...");
                      var cardData = (await callGetDeckCard({
                        "playerId": room.player.id,
                        "roomId": room.roomId,
                        "playerToken": playerToken
                      }))
                          .data;

                      if (cardData == false) {
                        showToast("It is not your turn!");
                        calledFunction = false;
                        return;
                      }

                      room.player.addElementCard(
                          ElementCard.fromString(cardData.toString()));
                      calledFunction = false;
                      setState(() {
                        listViewStartingIndex = listViewStartingIndex;
                      });
                    } else {
                      showToast("You cannot get deck card now");
                    }
                  },
                ),
              ),

              //Last Card
              drawLastCardDragTarget(
                  mediaQueryWidth * 0.15, mediaQueryHeight * 0.4),

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
                              decoration: BoxDecoration(
                                  //TODO: Make it responsive
                                  border: Border.all(
                                width: mediaQueryHeight * 0.0025,
                                color: Colors.black,
                              )),
                              child: buildMenu.createBuildMenuContent(
                                  mediaQueryWidth * 0.8 -
                                      mediaQueryHeight * 0.01,
                                  mediaQueryHeight * 0.64,
                                  room,
                                  playerToken),
                            ),
                          );
                        });
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
            ))
      ]);
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
                      child: Text("points: " + points.value.toString()),
                    ),
                  ),
                  Container(
                    width: mediaQueryWidth * 0.10,
                    child: RawMaterialButton(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0)),
                      child: Icon(Icons.clear),
                      onPressed: () {
                        _onWillPop();
                      },
                    ),
                    alignment: Alignment.topCenter,
                  ),
                ],
              )),
          Row(
            children: <Widget>[
              Container(
                width: mediaQueryWidth * 0.10,
                height: mediaQueryHeight * 0.50,
              ),
              Container(
                width: mediaQueryWidth * 0.10,
                height: mediaQueryHeight * 0.50,
                color: primaryGreen, //Colors.green,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.person),
                    Text(
                      room.otherPlayers[0].name,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text("Cards: " +
                        room.otherPlayers[0].cardsNumber.toString()),
                    Row(
                      children: <Widget>[
                        Icon(Icons.message),
                        Flexible(
                          child: Text(": " + room.otherPlayers[0].lastMessage),
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
                if (!(listViewStartingIndex.value + 6 >=
                    room.player.getElementCards().length)) {
                  return RawMaterialButton(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    child: Icon(Icons.arrow_forward, color: primaryGreen),
                    onPressed: () {
                      setState(() {
                        listViewStartingIndex.value += 6;
                      });
                    },
                  );
                } else {
                  return Container();
                }
              },
              child: RawMaterialButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0)),
                child: Icon(Icons.arrow_forward, color: primaryGreen),
                onPressed: () {
                  setState(() {
                    if (!(listViewStartingIndex.value + 6 >=
                        room.player.getElementCards().length)) {
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
          children: <Widget>[drawLeftSide(), drawMiddleSide(), drawRightSide()],
        ),
      ),
    );
  }

  Widget leaveButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: RaisedButton(
        child: Center(
          child: Text("Leave"),
        ),
        onPressed: () {
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.pop(context);
          Navigator.push(
              context, MaterialPageRoute(builder: (context) => HomeScreen()));
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
    ));
  }

  Widget drawLastCardDragTarget(double width, double height) {
    return DragTarget<ElementCard>(
      builder: (BuildContext context, List<card> incoming, rejected) {
        return room.lastCard.draw(width, height);
      },
      onWillAccept: (data) =>
          (data.group == room.lastCard.group ||
              data.period == room.lastCard.period) &&
          room.player.id == playerOnTurn &&
          !calledFunction,
      onAccept: (data) async {
        calledFunction = true;
        showToast("wait");
        cardToRemove = data;
        var dataToSend = {
          "cardUuid": data.uuid,
          "playerId": room.player.id,
          "cardName": data.name.toString(),
          "roomId": room.roomId,
          "playerToken": playerToken,
        };

        dataToSend["cardName"] = data.name;

        var isPlaced = (await callPlaceCard.call(dataToSend)).data;

        if (isPlaced) {
          toastMsg = "You have placed card successfully";
          showToast(toastMsg);
          room.player.removeElementCard(cardToRemove.name, cardToRemove);
          calledFunction = false;
          setState(() {
            listViewStartingIndex = listViewStartingIndex;
          });
        } else {
          toastMsg = "The group and the period do not coincide!";
          showToast(toastMsg);
          calledFunction = false;
        }
      },
      onLeave: (data) {},
    );
  }
}
