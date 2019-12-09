import 'package:flutter/material.dart';

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

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    return Scaffold(
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
    );
  }
}
