import 'dart:convert';

import 'package:chemistry_game/models/player.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';
import 'package:chemistry_game/models/element_card.dart';

class BuildRoomScreen extends StatefulWidget {

  final String roomId;
  BuildRoomScreen({this.roomId});

  @override
  _BuildRoomScreenState createState() => _BuildRoomScreenState(roomId: roomId);
}

class _BuildRoomScreenState extends State<BuildRoomScreen> {

  String roomId;
  _BuildRoomScreenState({this.roomId});


  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    Player player = new Player(name: "ivan", id: "23232");
    player.setElementCards();
    print(player.getElementCards());
    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;
    /*final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'readFromDb',
    );*/

    List<Container> df = List<Container>();

    player.getElementCards().forEach( (e) => df.add(e.draw(mediaQueryWidth * 0.1, mediaQueryHeight * 0.2)));

    ListView getElementCards() {
      return ListView(
        scrollDirection: Axis.horizontal,
        children: df//<Widget>[
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

    return Scaffold(
      body: Row(

        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: <Widget>[
          Column(
            children: <Widget>[

              //Left side

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
                    /*dynamic resp = callable.call();
                    print(resp.toString());
                    var json = jsonDecode(resp.;
                    print(json.toString());*/
                  },
                ),
              ),
            ],
          ),

          //Middle side

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
                child: getElementCards()
              )
              /*Container(
                height: mediaQueryHeight * 0.2,
                width: mediaQueryWidth * 0.6,
                color: Colors.blue,
                child: Container(), // draw cards
              ),*/
            ]
          ),

          //Right side

          Column(

            children: <Widget>[

              Container(
                width: mediaQueryWidth * 0.20,
                height: mediaQueryHeight * 0.25,
                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.settings, color: Colors.blue,),
                  onPressed: () {},
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
                  onPressed: () {},
                ),
              ),
            ],
          )

        ],
      ),
    );


  }
  Column createBuildMenuContent(double width, double height) {
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
        //Combinations made
        Container(
          width: width,
          height: height * 0.8,
          decoration: BoxDecoration(
              border: Border.all(
                  width: 0.5
              )
          ),
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

            ],
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
}
