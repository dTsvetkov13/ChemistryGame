import 'package:chemistry_game/screens/home/home.dart';
import 'package:flutter/material.dart';

class PlayerData{
  String name;
  int points;

  PlayerData(this.name, this.points);
}

class SummaryScreen extends StatelessWidget {

  final List<PlayerData> playersData = new List<PlayerData>();

  SummaryScreen(List<String> players)
  {
    for(int i = 0; i < players.length; i++)
    {
      var playerSplitted = players[i].split(",");
      playersData.add(PlayerData(playerSplitted[0], int.parse(playerSplitted[1])));
    }
  }

  List<DataRow> getDataRows() {
    List<DataRow> dataRows = new List<DataRow>();

    for(int i = 0; i < playersData.length; i++) {
      dataRows.add(
        new DataRow(cells: [
          DataCell(Text(((i+1).toString()))),
          DataCell(Text(playersData[i].name)),
          DataCell(Text(playersData[i].points.toString()))
        ])
      );
    }

    return dataRows;
  }

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: DecoratedBox(
                position: DecorationPosition.background,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("images/background4.png"),
                        fit: BoxFit.cover
                    )
                ),
              ),
            ),
          ),
          Column(
            children: <Widget>[
              Container(
                height: 0.1,
              ),
              Center(
                child: Text(
                  "Summary",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                  ),
                )
              ),
              Container(
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
                child: DataTable(
                    columns: [
                      DataColumn(label: Text("Place")),
                      DataColumn(label: Text("Name")),
                      DataColumn(label: Text("Points"))
                    ],
                    rows: getDataRows()
                ),
              ),
              Center(
                child: RaisedButton(
                  child: Text("Go to Home"), //TODO: maybe change it to "Lobby"
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) => HomeScreen())
                    );
                  },
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
