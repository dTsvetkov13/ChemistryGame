import 'package:chemistry_game/screens/home/home.dart';
import 'package:chemistry_game/screens/home/main_screen.dart';
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
    return Scaffold(
      body: Column(
        children: <Widget>[
          Center(child: Text("Summary")),
          DataTable(
            columns: [
              DataColumn(label: Text("Place")),
              DataColumn(label: Text("Name")),
              DataColumn(label: Text("Points"))
            ],
            rows: getDataRows()
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
      ),
    );
  }
}
