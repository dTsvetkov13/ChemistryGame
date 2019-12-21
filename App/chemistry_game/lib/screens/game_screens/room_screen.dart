import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/services.dart';

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

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;
    /*final HttpsCallable callable = CloudFunctions.instance.getHttpsCallable(
      functionName: 'readFromDb',
    );*/

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

                Row(

                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //TODO : see why this does not work

                  children: <Widget>[
                    //Deck
                    Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.cyanAccent,
                    ),
                    //Last Card
                    Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.purpleAccent,
                    ),
                    //Build Menu
                    Container(
                      height: mediaQueryHeight * 0.4,
                      width: mediaQueryWidth * 0.15,
                      color: Colors.deepOrange,
                    ),
                  ],
                ),

                Container(
                  height: mediaQueryHeight * 0.15,
                  width: mediaQueryWidth * 0.6,
                ),

                Container(
                  height: mediaQueryHeight * 0.2,
                  width: mediaQueryWidth * 0.6,
                  color: Colors.blue,
                  child: Container(), // draw cards
                ),
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

    /*return Scaffold(
      body: Column(
        children: <Widget>[
          Row(

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: <Widget>[
              Container(
                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.arrow_downward, color: Colors.blue),
                  onPressed: () {
                    /*dynamic resp = callable.call();
                    print(resp.toString());
                    var json = jsonDecode(resp.;
                    print(json.toString());*/
                  },
                ),
              ),
              Container(
                width: mediaQueryWidth * 0.5,
                height: mediaQueryHeight * 0.2,
                color: Colors.yellowAccent,
              ),
              Container(

                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.message, color: Colors.blue,),
                  onPressed: () {},
                ),
              ),
            ],
          ),

          Row(
            children: <Widget> [
              Container(
                height: mediaQueryHeight * 0.5,
                child: Container(), // draw cards
              ),
              Column(
                children: <Widget>[

                ],
              ),
              Container()
            ]
          ),

          Row(

            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: <Widget>[
              Container(
                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.arrow_downward, color: Colors.blue),
                  onPressed: () {},
                ),
              ),
              Container(
                width: mediaQueryWidth * 0.5,
                height: mediaQueryHeight * 0.2,
                color: Colors.yellowAccent,
              ),
              Container(

                child: RawMaterialButton(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)
                  ),
                  child: Icon(Icons.settings, color: Colors.blue,),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );*/
  }
}
