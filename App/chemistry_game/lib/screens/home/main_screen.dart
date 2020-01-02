import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:provider/provider.dart';

enum gameType {
  singleGame,
  teamGame
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

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

  @override
  Widget build(BuildContext context) {


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
              onPressed: () {
                //TODO: whether the selectedGameType it open a InvitationMenu or navigates to a GameRoom
                switch(currGT.value) {
                  case(gameType.singleGame) : {
                    String roomId = "ROOM 1";
                    //Request singleGameRoom
                    //Get the id of the room
                    //Navigate to a room
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BuildRoomScreen(roomId: roomId))
                    );
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
