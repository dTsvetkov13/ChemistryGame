import 'dart:convert';

import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ignore: must_be_immutable
class BuildRoomScreen extends StatefulWidget {

  final String roomId;
  BuildRoomScreen({this.roomId});

  Player player = new Player("ivan", "23232");

  @override
  _BuildRoomScreenState createState() => _BuildRoomScreenState(roomId: roomId, player: player);
}

class _BuildRoomScreenState extends State<BuildRoomScreen> {

  Player player;
  String roomId;
  _BuildRoomScreenState({this.roomId, this.player});

  ValueNotifier<int> listViewStartingIndex = ValueNotifier<int>(0);
  ValueNotifier<BuildMenuShowingCardsType> buildMenuShowingCardsType =
                          new ValueNotifier<BuildMenuShowingCardsType>(BuildMenuShowingCardsType.ElementCards);


  bool showElementCards = true;

  ElementCard lastCard = ElementCard(name: "H2", group: "2A", period: 1); //TODO: get this from the DB

  Reaction currReaction = Reaction();

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);
    //player.setElementCards();
    player.setCombinationCards();

    currReaction.addReactant(0, ElementCard(name: "H2", group: "2A", period: 1));
    currReaction.addReactant(1, ElementCard(name: "O2", group: "2A", period: 1));
    currReaction.addProduct(0, ElementCard(name: "H2O", group: "2A", period: 2));

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
    combinationCards.add(player.combinationCards.elementAt(0).draw(50, 50));

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
                      color: Colors.cyanAccent,
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
                                  decoration: BoxDecoration( //TODO: Make it responsible
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
              player.getElementCards().forEach((card) => cards.add(card.drawDraggableElementCard(width * 0.1, height)));
              break;
            case (BuildMenuShowingCardsType.ReactionCards):
              player.combinationCards.forEach((card) => cards.add(card.drawDraggable(width * 0.1, height)));//TODO: combinationCards change name
              break;
            /*case (BuildMenuShowingCardsType.ElementCards):
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
      onPressed: () {
        //check if reaction is correct
        //true: reaction.clear(), add bonus points to the player and show a toast for correct reaction
        //false: show a message which report that the reaction is incorrect
        Fluttertoast.showToast(
          msg: "Incorrect reaction",
          timeInSecForIos: 1,
          gravity: ToastGravity.BOTTOM,
          toastLength: Toast.LENGTH_SHORT
        );
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
        return lastCard.draw(width, height);
      },

      onWillAccept: (data) => data.group == lastCard.group || data.period == lastCard.period,

      onAccept: (data) {
        setState(() {
          lastCard = data;
        });
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