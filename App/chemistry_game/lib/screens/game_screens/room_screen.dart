import 'dart:async';

import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/fieldPlayer.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:chemistry_game/screens/game_screens/summary_screen.dart';
import 'package:chemistry_game/screens/home/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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

  @override
  _BuildRoomScreenState createState() => _BuildRoomScreenState(roomId: roomId, playerId: playerId,
                    lastCardData: lastCardData,
                    playerName: playerName, player: player, firebaseMessaging: firebaseMessaging, fieldPlayers: this.fieldPlayers);
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

  bool showElementCards = true;
  bool calledFunction = false;

  Reaction currReaction = Reaction();

  final HttpsCallable callPlaceCard = CloudFunctions.instance.getHttpsCallable(
    functionName: 'placeCard',
  );

  final HttpsCallable callCompleteReaction = CloudFunctions.instance.getHttpsCallable(
    functionName: 'completeReaction',
  );

  final HttpsCallable callGetDeckCard = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getDeckCard',
  );

  final HttpsCallable callSendChatMsgToEveryone = CloudFunctions.instance.getHttpsCallable(
    functionName: 'sendChatMsgToEveryone',
  );

  final HttpsCallable callAddLeftPlayer = CloudFunctions.instance.getHttpsCallable(
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

  var points = new ValueNotifier<int>(0);

  String playerToken;
  var toastMsg;
  var cardToRemove = new ElementCard();
  var playerOnTurn;
  var playerOnTurnName = "";

  @override
  void initState() {
    print("called");
    super.initState();
    firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          var data = message["notification"];
          print("Message received in room screen: $data");

          switch(data["title"])
          {
            //TODO: chekc if Player Cards is used
            case("Player Cards"):
              var elementCards = message["data"]["elementCards"];
              var compoundCards = message["data"]["compoundCards"];

              print("Element Cards: " + elementCards);
              print("Compound Cards: " + compoundCards);
              break;
            case("Start"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              print(toastMsg);
              break;
            case("Game Finished"):
              print("Game Finished");
              showToast("Game finished");

              if(message.containsKey("data")) {
                var firstPlace = message["data"]["firstPlace"];
                var secondPlace = message["data"]["secondPlace"];
                var thirdPlace = message["data"]["thirdPlace"];
                var fourthPlace = message["data"]["fourthPlace"];
                print(firstPlace);
                print(secondPlace);
                print(thirdPlace);
                print(fourthPlace);


                if(firstPlace == null) break;
                else {
                  List<String> places = [
                    firstPlace.toString(),
                    secondPlace.toString(),
                    thirdPlace.toString(),
                    fourthPlace.toString()
                  ];
                  print(places[0]);
                  Navigator.pop(context);
                  Navigator.push(context,
                    MaterialPageRoute(builder: (context) =>
                      SummaryScreen(places)
                    ));
                }
              }
              break;
            case("Points Updated"):
              points.value = int.parse(message["data"]["pointsToAdd"]);
              print(message["notification"]["body"]);
              break;
            case("Placed Card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              player.removeElementCard(cardToRemove.name, cardToRemove);
              print(cardToRemove.name);
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
              print(playerOnTurn);

              break;
            case("Missed Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              var currPlayerId = message["data"]["playerId"];

              if(currPlayerId == playerId) {
                var cardToAddString = message["data"]["cardToAdd"];
                print(cardToAddString);

                player.addElementCard(ElementCard.fromString(cardToAddString.toString()));
                setState(() {
                  listViewStartingIndex = listViewStartingIndex;
                });
              }
              break;
            case("New Last Card"):
              var newLastCard = message["data"]["newLastCard"];
              //var newLastCardSplitted = newLastCard.toString().split(",");
              var splitted = newLastCard.toString().split(",");
              setState(() {
                lastCardData = ElementCard(name: splitted[0], group: splitted[1], period: int.parse(splitted[2]));
              });
              break;
            case("Complete Reaction Failed"):
              toastMsg = message["notification"]["body"];
              print(toastMsg);
              currReaction.clear();
              showToast(toastMsg);
              break;
            case("Cannot Place Card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              calledFunction = false;
              print(toastMsg);
              break;
            case("Receive Deck Card"):
              var cardData = message["data"]["cardToGiveData"];

              //var cardDataSplitted = cardData.toString().split(",");
              print("Deck card: " + cardData);
              //player.addElementCard(ElementCard(name: cardDataSplitted[0], group: cardDataSplitted[1], period: int.parse(cardDataSplitted[2])));
              player.addElementCard(ElementCard.fromString(cardData.toString()));
              calledFunction = false;
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });
              break;
            case("You Finished"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);

              finished = true;
              break;
            case("Chat Msg"):
              var msgSender = message["data"]["sender"];
              var msg = message["data"]["msg"];
//              showTopToast(chatMsgSender + ": " + chatMsg.value.toString());
              print("Before loop");
              for(int i = 0; i < fieldPlayers.length; i++) {
                print("in loop");
                if(fieldPlayers[i].name == msgSender) {
                  fieldPlayers[i].lastMessage = msg.toString();
                  break;
                }
              }
              break;
            case("Empty Side"):
              toastMsg = message["notification"]["body"];
              print(toastMsg);
              currReaction.clear();
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

              print(player.compoundCards.length);
              print(player.elementCards.length);
              print("Before add card");

              print(toastMsg);
              showToast(toastMsg);

              setState(() {
                if (buildMenuShowingCardsType.value ==
                    BuildMenuShowingCardsType.ElementCards) {
                  buildMenuShowingCardsType.value =
                      BuildMenuShowingCardsType.ReactionCards;
                }
                else {
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ElementCards;
                }
              });
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });

              if(message["data"].containsKey("cardToAdd")) //TODO: see why this do not work
              {
                cardToAdd = message["data"]["cardToAdd"];
                print("CardToAdd: " + cardToAdd);

                if(cardToAdd.contains(","))
                {
                  //var cardData = cardToAdd.split(",");
                  //player.addElementCard(ElementCard(name: cardData[0], group: cardData[1], period: int.parse(cardData[2])));
                  player.addElementCard(ElementCard.fromString(cardToAdd.toString()));
                }
                else
                {
                  player.addCompoundCard(CompoundCard.fromString(cardToAdd));
                }
              }
              print("After check the cardToAdd");
              setState(() {
                buildMenuShowingCardsType = buildMenuShowingCardsType;
              });

              break;
          }

          return;
        }
    );
    firebaseMessaging.getToken().then((token) {
      playerToken = token;
      print("Token : $playerToken");
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

  List<String> textMessages = ["Hi", "Well played", "Good job", "Be careful"];
  List<PopupMenuItem> textMessagesWidgets = new List<PopupMenuItem>();

  bool finished = false;
  String chatMsgSender = "";
  var chatMsg = new ValueNotifier("");

  final GlobalKey _menuKey = new GlobalKey();

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

    print("PLayer names : " + fieldPlayers.toString());
    print("Once");
    currReaction.rightSideCards.values.forEach((card) {
      if(card != null)
      {
        print("Right side: " + card.name);
      }
    });
    currReaction.leftSideCards.values.forEach((card) {
      if(card != null)
      {
        print("Left side: " + card.name);
      }
    });

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    List<Draggable> elementCards = List<Draggable>();
    List<Container> combinationCards = List<Container>();

    player.getElementCards().forEach( (e) => elementCards.add(e.drawDraggableElementCard(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2)));

    ListView getElementCards(int startingIndex) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: elementCards.sublist(startingIndex,
            startingIndex+6 > player.getElementCards().length ? player.getElementCards().length : startingIndex+6)//<Widget>[
      );
    }

    ListView getCombinationCards() {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: combinationCards,
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
                            background: Colors.lightGreenAccent,
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
                            background: Colors.lightGreenAccent,
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Row(

          mainAxisAlignment: MainAxisAlignment.spaceBetween,

          children: <Widget>[
            Column(
              children: <Widget>[

                ///Left side

                Container(
                  width: mediaQueryWidth * 0.20,
                  height: mediaQueryHeight * 0.25,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: mediaQueryWidth * 0.10,
//                      height: mediaQueryHeight * 0.25,
                        child: PopupMenuButton(
                          key: _menuKey,
                          child: RawMaterialButton(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9.0)
                            ),
                            child: Icon(Icons.message, color: Colors.blue,),
                            onPressed: () {
                              dynamic state = _menuKey.currentState;
                              state.showButtonMenu();
                            },
                          ),
                          itemBuilder: (_) => textMessagesWidgets,
                          onSelected: (value) {
                            print(value);

                            var data = {
                              "msg": value,
                              "senderName": "Minzuhar", ///TODO: change it to player.name
                              "senderId": player.id
                            };

                            callSendChatMsgToEveryone(data);
                          },
                        ),

                        alignment: Alignment.topCenter,
                      ),
                      Container(
                        width: mediaQueryWidth * 0.10,
//                height: mediaQueryHeight * 0.25,

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
//                    color: Colors.yellowAccent,
                      child: Column(
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
                              Text(
                                ": " + fieldPlayers[2].lastMessage
                              ),
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
                          child: Icon(Icons.arrow_back, color: Colors.blue),
                          onPressed: () {
                            setState(() {
                              //showElementCards = true;
//                            if (!(listViewStartingIndex.value - 6 < 0)) {
                                listViewStartingIndex.value -= 6;
//                            }
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
                      child: Icon(Icons.arrow_back, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          //showElementCards = true;
                          if(!(listViewStartingIndex.value - 6 < 0)) {
                            listViewStartingIndex.value -= 6;
                          }
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),

            ///Middle side

            Column(
              children: <Widget> [
                Container(
                  height: mediaQueryHeight * 0.1,
                  width: mediaQueryWidth * 0.6,
//                color: Colors.black,
                  child: Center(
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.person
                        ),

                        Column(
                          children: <Widget>[
                            Text(
                              fieldPlayers[1].name + " ",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                            Text(
                              "Cards: " + fieldPlayers[1].cardsNumber.toString()
                            ),

                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Icon(Icons.message),
                            Text(
                                ": " + fieldPlayers[1].lastMessage
                            ),
                          ],
                        )
                      ],
                    ),
                  ), // draw cards
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
                              await callGetDeckCard({"playerId": playerId, "roomId": roomId, "playerToken": playerToken});
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
//                child: ValueListenableBuilder(
//                  valueListenable: chatMsg,
//                  child: Center(
//                    child: Text(
//                      ""
//                    )
//                  ),
//                  builder: (BuildContext context, String value, Widget child) {
//                    return Center(
//                      child: Text(
//                        chatMsgSender + ": " + chatMsg.value
//                      ),
//                    );
//                  },
//                ),
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
            ),

            ///Right side
            Column(

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
//                        child: Icon(Icons.settings, color: Colors.blue,),
//                        onPressed: () {
//                          showSettingsDialog(mediaQueryWidth * 0.3, mediaQueryHeight * 0.6);
//                        },
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
//                    color: Colors.green,
                      child: Column(
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
                              Text(
                                  ": " + fieldPlayers[0].lastMessage
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
                          child: Icon(Icons.arrow_forward, color: Colors.blue),
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
                      child: Icon(Icons.arrow_forward, color: Colors.blue),
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
            )
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
            width: width,
            height: height * 0.3,
            child: RaisedButton(
              child: Text("Elements"),
              onPressed: () {
                setState(() {
                  print("Element");
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ElementCards;
                });
              },
            ),
          ),
          Container(
            width: width,
            height: height * 0.3,
            child: RaisedButton(
              child: Text("Compounds"),
              onPressed: () {
                setState(() {
                  print("Reaction");
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ReactionCards;
                });
              },
            ),
          ),
          Container(
            width: width,
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
              break;
            case (BuildMenuShowingCardsType.ReactionCards):
              player.compoundCards.forEach((card) => cards.add(card.drawDraggable(width * 0.1, height)));
              break;
            /*case (BuildMenuShowingCardsType.AccelerationCards):
              break;*/
            default: print("Error, invalid type");
          }

          return ListView(
            scrollDirection: Axis.horizontal,
            children: cards,
          );
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

  void showSettingsDialog(double width, double height) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Center(child: Text("Settings")),
          //content: createBuildMenuContent(),
          content: Container(
            width: width,
            height: height,
            decoration: BoxDecoration( //TODO: Make it responsible
                border: Border.all(
                  width: 0.2,
                  color: Colors.black,
                )
            ),
            child: settingsOptions(width, height)
          ),
        );
      }
    );
  }

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
                //drawAddCardFieldButton(width, height),
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

          if(finished) {
            showToast("You have already finished");
            return;
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

          print("Left cards: " + leftCards.toString());
          print("Right cards: " + rightCards.toString());

          var dataToSend = {
            "playerId": playerId,
            "playerToken": playerToken,
            "leftSideCards": leftCards,
            "rightSideCards": rightCards
          };
          showToast("wait..."); //TODO: the msg can be changed
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
          "roomId": roomId,
          "playerToken": playerToken,
        };

        dataToSend["cardName"] = data.name;

        print("Place card: " + data.uuid + " : " + data.name);

        await callPlaceCard.call(dataToSend);
      },

      onLeave: (data) {

      },
    );
  }
}

enum BuildMenuShowingCardsType {
 ElementCards,
 ReactionCards
 ///AccelerationCards // in future
}