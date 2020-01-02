import 'dart:convert';

import 'package:chemistry_game/models/player.dart';
import 'package:chemistry_game/models/reaction.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:chemistry_game/models/element_card.dart';

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

  bool showElementCards = true;


  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);
    player.setElementCards();
    player.setCombinationCards();

    Reaction reaction = new Reaction(ReactionType.Combination);
    reaction.addReactant(0, ElementCard(name: "H2", group: "2A", period: 1));
    reaction.addReactant(1, ElementCard(name: "O2", group: "2A", period: 1));
    reaction.addProduct(0, ElementCard(name: "H2O", group: "2A", period: 2));

    player.buildMenuReactions.value.add(reaction);
    player.buildMenuReactions.value.add(reaction);

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

    ListView getElementCards() {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: elementCards//<Widget>[
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
                  child: Icon(Icons.arrow_forward, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      showElementCards = true;
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

                  //TODO : see why this does not work

                  children: <Widget>[
                    //Deck
                    Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.cyanAccent,
                    ),


                    //Last Card
                    /*Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.purpleAccent,
                    ),*/
                    ElementCard(name: "H2", group: "3A", period: 1).draw(mediaQueryWidth * 0.15, mediaQueryHeight * 0.4),
                    //Build Menu
                    /*Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.deepOrange,
                    ),*/
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
                                //content: createBuildMenuContent(),
                                content: Container(
                                  width: mediaQueryWidth * 0.8,
                                  height: mediaQueryHeight * 0.8,
                                  decoration: BoxDecoration( //TODO: Make it responsible
                                      border: Border.all(
                                        width: 0.2,
                                        color: Colors.black,
                                      )
                                  ),
                                  child: createBuildMenuContent(mediaQueryWidth * 0.8, mediaQueryHeight * 0.7),
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



              /*SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Expanded(
                    child: ListView(
                        children: <Widget>[
                          Container(
                            height: mediaQueryHeight * 0.2,
                            width: mediaQueryWidth * 0.3,
                            color: Colors.cyanAccent,
                          ),
                          Container(
                            height: mediaQueryHeight * 0.2,
                            width: mediaQueryWidth * 0.3,
                          ),
                          Container(
                            height: mediaQueryHeight * 0.2,
                            width: mediaQueryWidth * 0.3,
                            color: Colors.cyanAccent,
                          ),Container(
                            height: mediaQueryHeight * 0.2,
                            width: mediaQueryWidth * 0.3,
                          ),Container(
                            height: mediaQueryHeight * 0.2,
                            width: mediaQueryWidth * 0.3,
                            color: Colors.cyanAccent,
                          ),


                        ]
                    ),
                  )
              )*/
              Container(
                height: mediaQueryHeight * 0.2,
                width: mediaQueryWidth * 0.6,
                child: showElementCards ? getElementCards() : getCombinationCards()
              )
              /*Container(
                height: mediaQueryHeight * 0.2,
                width: mediaQueryWidth * 0.6,
                color: Colors.blue,
                child: Container(), // draw cards
              ),*/
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
                  child: Icon(Icons.arrow_back, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      showElementCards = false;
                      //print("Arrow Back clicked : {$showElementCards}");
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

  Column createBuildMenuContent(double width, double height) {



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
                drawEditButton(width, height, reaction),
                reaction.draw(width, height)
              ],
            ),
          ),
          drawDeleteButton(width, height, reaction)

        ]
      ),
    );
  }

  Widget drawCompleteButton(double width, double height) {
    return IconButton(
      icon: Icon(Icons.check),
      color: Colors.green,
      onPressed: () {

      },
    );
  }

  Widget drawEditButton(double width, double height, Reaction reaction) {
    return IconButton(
      icon: Icon(Icons.edit),
      color: Colors.grey,
      onPressed: () {
        reaction.showEdinMenu.value = !reaction.showEdinMenu.value;
      },
    );
  }

  Widget drawDeleteButton(double width, double height, Reaction reaction) {
    return Container(
      width: width * 0.1,
      height: height * 0.7,
      child: IconButton(
        icon: Icon(Icons.delete_forever),
        color: Colors.red,
        onPressed: () {
          setState(() {
            player.deleteReaction(reaction);
            print(player.buildMenuReactions.value);
          });
        },
      ),
    );
  }
}