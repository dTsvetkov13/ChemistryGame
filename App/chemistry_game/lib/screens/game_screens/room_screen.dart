import 'dart:convert';

import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/models/compound_card.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:chemistry_game/screens/game_screens/summary_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: must_be_immutable
class BuildRoomScreen extends StatefulWidget {

  FirebaseMessaging firebaseMessaging;
  final String roomId;
  final String playerId;
  final ElementCard lastCardData;
  final playersNames;
//  final playerElementCards;
//  final playerCompoundCards;
  final playerName;
  Player player;
  BuildRoomScreen({this.roomId, this.playerId,
                    this.lastCardData, this.playersNames, this.playerName, this.player, this.firebaseMessaging});

  @override
  _BuildRoomScreenState createState() => _BuildRoomScreenState(roomId: roomId, playerId: playerId,
                    lastCardData: lastCardData, playersNames: playersNames,
                    playerName: playerName, player: player, firebaseMessaging: firebaseMessaging);
}

class _BuildRoomScreenState extends State<BuildRoomScreen> {

  FirebaseMessaging firebaseMessaging;
  ElementCard lastCardData;
  String playerId;
  String roomId;
  var playersNames;
  var playerName;
  var leftPlayerName;
  var rightPlayerName;
  var topPlayerName;
  Player player;
  _BuildRoomScreenState({this.roomId, this.playerId, this.lastCardData, this.playersNames,
                          this.playerName, this.player, this.firebaseMessaging});


//  Player player = new Player("Denis", "232"); //= new Player("Denis", playerId);
//  player.setPlayerData(playerName, playerId);

  ValueNotifier<int> listViewStartingIndex = ValueNotifier<int>(0);
  ValueNotifier<BuildMenuShowingCardsType> buildMenuShowingCardsType =
                          new ValueNotifier<BuildMenuShowingCardsType>(BuildMenuShowingCardsType.ElementCards);

  bool showElementCards = true;

  //ElementCard lastCard = ElementCard(name: "H2", group: "2A", period: 1); //TODO: get this from the DB

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

  //FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String playerToken;
  var toastMsg;
  var cardToRemove = new ElementCard();
  var playerOnTurn;

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
            case("Placed Card"):
              player.removeElementCard(cardToRemove.name, cardToRemove);
              print(cardToRemove.name);
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });
              break;
            case("Not Your Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              break;
            case("Incorrect card"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);
              break;
            case("Player Turn"):
              toastMsg = message["notification"]["body"];
              showToast(toastMsg);

              playerOnTurn = message["data"]["playerId"];
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
              print(toastMsg);
              break;
            case("Receive Deck Card"):
              var cardData = message["data"]["cardToGiveData"];

              //var cardDataSplitted = cardData.toString().split(",");
              print("Deck card: " + cardData);
              //player.addElementCard(ElementCard(name: cardDataSplitted[0], group: cardDataSplitted[1], period: int.parse(cardDataSplitted[2])));
              player.addElementCard(ElementCard.fromString(cardData.toString()));
              setState(() {
                listViewStartingIndex = listViewStartingIndex;
              });
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

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);
    //player.setElementCards();
    //player.setPlayerData(playerName, playerId);
//    player.setCombinationCards();
    print("PLayer names : " + playersNames);
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

//    currReaction.addReactant(0, ElementCard(name: "H2", group: "2A", period: 1));
//    currReaction.addReactant(1, ElementCard(name: "O2", group: "2A", period: 1));
//    currReaction.addProduct(0, ElementCard(name: "H2O", group: "2A", period: 2));

    //player.buildMenuReactions.value.add(reaction);
    //player.buildMenuReactions.value.add(reaction);

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;


    /*final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'readFromDb',
    );*/



    //List<Container> elementCards = List<Container>();
    List<Draggable> elementCards = List<Draggable>();
    List<Container> combinationCards = List<Container>();

    player.getElementCards().forEach( (e) => elementCards.add(e.drawDraggableElementCard(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2)));
//    combinationCards.add(player.compoundCards.elementAt(0).draw(50, 50));

    ListView getElementCards(int startingIndex) {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: elementCards.sublist(startingIndex,
            startingIndex+6 > player.getElementCards().length ? player.getElementCards().length : startingIndex+6)//<Widget>[
          /*ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          ElementCard(name: "02", group: "2A", period: 1).draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2),
          */
          //player.getElementCards().forEach((e) => e.draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2))

        //],
      );
    }

    ListView getCombinationCards() {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: combinationCards,
      );
    }

    return Scaffold(
      body: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: <Widget>[
          Column(
            children: <Widget>[

              ///Left side

              Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.25,
                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.message, color: Colors.blue,),
                  onPressed: () {},
                ),

                alignment: Alignment.topLeft,
              ),

              Row(
                children: <Widget>[
                  Container(
                    width: mediaQueryWidth * 0.10,
                    height: mediaQueryHeight * 0.50,
                    color: Colors.yellowAccent,
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
                    /*dynamic resp = callable.call();
                    print(resp.toString());
                    var json = jsonDecode(resp.;
                    print(json.toString());*/
                  },
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
                color: Colors.black,
                child: Container(), // draw cards
              ),

              Container(
                height: mediaQueryHeight * 0.15,
                width: mediaQueryWidth * 0.6,
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
                          await callGetDeckCard({"playerId": playerId, "roomId": roomId, "playerToken": playerToken});
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
          ),

          ///Right side
          Column(

            children: <Widget>[

              Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.25,
                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.settings, color: Colors.blue,),
                  onPressed: () {
                    showSettingsDialog(mediaQueryWidth * 0.3, mediaQueryHeight * 0.6);
                  },
                ),

                alignment: Alignment.topRight,
              ),

              /*Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.05,
              ),*/

              Row(
                children: <Widget>[
                  Container(
                    width: mediaQueryWidth * 0.10,
                    height: mediaQueryHeight * 0.50,
                  ),
                  Container(
                    width: mediaQueryWidth * 0.10,
                    height: mediaQueryHeight * 0.50,
                    color: Colors.green,
                  ),
                ],
              ),

              /*Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.05,
              ),*/

              Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.25,
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
            ],
          )

        ],
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
          drawCardTypeButtons(width * 0.1, height),
          drawCardsAvailable(width * 0.85, height),
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
            width: width * 0.8,
            height: height * 0.3,
            child: RaisedButton(
              child: Text("E"),
              onPressed: () {
                setState(() {
                  print("Element");
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ElementCards;
                });
              },
            ),
          ),
          Container(
            width: width * 0.8,
            height: height * 0.3,
            child: RaisedButton(
              child: Text("C"),
              onPressed: () {
                setState(() {
                  print("Reaction");
                  buildMenuShowingCardsType.value = BuildMenuShowingCardsType.ReactionCards;
                });
              },
            ),
          ),
          Container(
            width: width * 0.8,
            height: height * 0.3,
            child: RaisedButton(
              child: Text("A"),
              onPressed: () {
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



  /*Column createBuildMenuContent(double width, double height) {
    List<Widget> buildMenuReactions = new List<Widget>();

    for(int i = 0; i < player.buildMenuReactions.value.length; i++) {
      buildMenuReactions.add(drawReactionRow(width, height * 0.4, player.buildMenuReactions.value[i]));
      buildMenuReactions.add(drawEditMenu(width, height * 0.4, player.buildMenuReactions.value[i]));
    }

    return Column(

      mainAxisAlignment: MainAxisAlignment.spaceAround,

      children: <Widget>[
        /*//cards available
        Column(
          children: <Widget>[
            //CombinationCards available
            Container(),
            //AcceleratorCards available
            Container()
          ],
        ),*/
        //Reactions made
        Container(
          width: width,
          height: height * 0.8,
          decoration: BoxDecoration(
              border: Border.all(
                  width: 0.5
              )
          ),
          child: ValueListenableBuilder(
            valueListenable: player.buildMenuReactions,
            builder: (context, value, child) {
              return ListView(
                scrollDirection: Axis.vertical,
                children:
                buildMenuReactions ?? Container(width:  width, height: height, color: Colors.blue,),
              );
            },
            child: ListView(
              scrollDirection: Axis.vertical,
              children:
                buildMenuReactions ?? Container(width:  width, height: height, color: Colors.blue,),
            ),
          ),
        ),
        //Buttons area
        Container(
          width: width * 0.3,
          height: height * 0.1,

          child: RaisedButton(
            child: Center(child: Text("Add Commbination")),
            onPressed: () {

            },
          ),
        )
      ],
    );
  }*/

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

  Container settingsOptions(double width, double height) {
    return Container(
      child: ListView(
        scrollDirection: Axis.vertical,
        children: <Widget>[
          Container(
            width: width,
            height: height * 0.4,
            color: Colors.blue,
          ),
          Container(
            width: width,
            height: height * 0.4,
            color: Colors.yellowAccent,
          ),
          Container(
            width: width,
            height: height * 0.4,
            color: Colors.blue,
          ),
          Container(
            width: width,
            height: height * 0.4,
            color: Colors.teal,
          ),

          ///LeaveOption
        ],
      ),
    );
  }

  /*
  Widget drawEditMenu(double width, double height, Reaction reaction) {
    return ValueListenableBuilder(
      valueListenable: reaction.showEdinMenu,
      builder: (context, value, child) {
        return AnimatedCrossFade(
          duration: Duration(seconds: 1),
          firstChild: Container(
            width: width,
            height: 0,
            color: Colors.white,
          ),
          secondChild: Container(
              width: width,
              height: height,
              color: Colors.purple
          ),
          crossFadeState: !reaction.showEdinMenu.value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
        );
      },
      child: AnimatedCrossFade(
        duration: Duration(seconds: 3),
        firstChild: Container(
          width: width,
          height: 0,
          color: Colors.white,
        ),
        secondChild: Container(
            width: width,
            height: height,
            color: Colors.purple
        ),
        crossFadeState: !reaction.showEdinMenu.value ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      ),
    );
  }*/

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
    return IconButton(
      icon: Icon(Icons.check),
      color: Colors.green,
      onPressed: () async {

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
    );
  }

  /*Widget drawEditButton(double width, double height, Reaction reaction) {
    return IconButton(
      icon: Icon(Icons.edit),
      color: Colors.grey,
      onPressed: () {
        reaction.showEdinMenu.value = !reaction.showEdinMenu.value;
      },
    );
  }*/

  Widget drawDeleteButton(double width, double height, Reaction reaction) {
    return Container(
      width: width,
      height: height,
      child: IconButton(
        icon: Icon(Icons.delete_forever),
        color: Colors.red,
        onPressed: () {
          reaction.clear();
        },
      ),
    );
  }

  Widget drawLastCardDragTarget(double width, double height) {
    return DragTarget<ElementCard>(
      builder: (BuildContext context, List<card> incoming, rejected) {
        return lastCardData.draw(width, height);
      },

      onWillAccept: (data) => (data.group == lastCardData.group || data.period == lastCardData.period) && playerId == playerOnTurn,

      onAccept: (data)
      async {
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