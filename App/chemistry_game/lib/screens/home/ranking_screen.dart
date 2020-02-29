
import 'package:chemistry_game/theme/colors.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:chemistry_game/models/element_card.dart';
import 'package:chemistry_game/models/player.dart';
import 'package:fluttertoast/fluttertoast.dart';

class RankingScreen extends StatefulWidget {
  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {

  final HttpsCallable callGetTopTen = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getTopTen',
  );

  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  String playerToken;
  var receivedData = new ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          var data = message["notification"];
          print("Message received: $data");

          if(message.containsKey('data'))
          {
            var msgData = message['data']['cardToAdd'];
            print("Message Data: $msgData");
          }

          return;
        }
    );
    _firebaseMessaging.getToken().then((token) async {
      playerToken = token;
      print("Token : $playerToken");

      var data = {
        "sortedBy": "singleGameWins"
      };
      print("Before data");
      receivedData.value = (await callGetTopTen.call(data)).data;
      print(receivedData.value);
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

  var dropdownValue = ValueNotifier<String>("Single Game Wins");

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    Widget topBar() {
      return Container(
          width: mediaQueryWidth,
          height: mediaQueryHeight * 0.2,
//        color: Colors.blueGrey,
          child: Row(
              children: <Widget> [
                Container(
                  width: mediaQueryWidth * 0.2,
                  child: Center(
                    child: Text(
                      "Ranking",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: mediaQueryWidth * 0.4,
                ),
                Container(
                  width: mediaQueryWidth * 0.1,
                  child: Center(
                    child: Text(
                      "Order by: "
                    )
                  ),
                ),
                Container(
                  width:  mediaQueryWidth * 0.2,
                  child: DropdownButton<String>(
                    value: dropdownValue.value,
                    icon: Icon(Icons.arrow_downward),
                    iconSize: 24,
                    elevation: 16,
                    style: TextStyle(
                        color: secondaryPink//Colors.deepPurple
                    ),
                    underline: Container(
                      height: 2,
                      color: secondaryPink//Colors.deepPurpleAccent,
                    ),
                    onChanged: (String newValue) async {
                      String sortedBy = "";
                      switch(newValue)
                      {
                        case("Single Game Wins"):
                          sortedBy = "singleGameWins";
                          break;
                        case("Team Game Wins"):
                          sortedBy = "teamGameWins";
                          break;
                      }
                      var data = {
                        "sortedBy": sortedBy
                      };

                      receivedData.value = (await callGetTopTen.call(data)).data;

                      setState(() {
                        dropdownValue.value = newValue;
                      });
                    },
                    items: <String>["Single Game Wins", "Team Game Wins"]
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                        .toList(),
                  ),
                )
              ]
          )
      );
    }

    Widget drawRanking() {

      List<DataRow> users = new List<DataRow>();

//      users.add(drawUser(mediaQueryWidth * 0.7, mediaQueryHeight * 0.2, "Name", "Wins"));

      for(int i = 0; i < receivedData.value.length; i++) {
        print(receivedData.value[i]);
        users.add(DataRow(
            cells: [
              DataCell(Text((i+1).toString(), style: TextStyle(fontWeight: FontWeight.bold),)),
              DataCell(Text(receivedData.value[i]["name"], style: TextStyle(fontWeight: FontWeight.bold))),
              DataCell(Text(receivedData.value[i]["wins"].toString(), style: TextStyle(fontWeight: FontWeight.bold)))
            ]
        ));//users.add(drawUser(mediaQueryWidth * 0.7, mediaQueryHeight * 0.2, receivedData.value[i]["name"], receivedData.value[i]["wins"].toString()));
      }

      return Container(
        width: mediaQueryWidth * 0.8,
        height: mediaQueryHeight * 0.7,
        decoration: BoxDecoration(
            border: new Border.all(
                color: Colors.black,
                width: 3.0,
                style: BorderStyle.solid
            ),
            borderRadius: new BorderRadius.all(new Radius.circular(10.0))
        ),
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            DataTable(
              columns: [
                DataColumn(label: Text("Place", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text("Wins", style: TextStyle(fontWeight: FontWeight.bold)))
              ],
              rows: users
            )
          ],
        )
      );
    }

    return Column(
      children: <Widget>[
        topBar(),
        ValueListenableBuilder(
          valueListenable: receivedData,
          builder: (BuildContext context, var value, Widget child) {
            print("Changed");
            print(receivedData.value);
            return drawRanking();
          },
          child: drawRanking(),
        )
      ],
    );


  }
}
