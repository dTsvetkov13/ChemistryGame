import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class ElementCard extends card {
  String name;
  String group;
  int period;
  bool isDiatomic = false;

  ElementCard({this.name, this.group, this.period}) {
    List<String> diatomicElements = new List<String>();
    diatomicElements = ["H", "O", "N", "I", "F", "Cl", "Br"];

    for (int i = 0; i < diatomicElements.length; i++) {
      if (this.name == diatomicElements[i]) {
        isDiatomic = true;
      }
    }
  }

  ElementCard.fromString(String data) {
    var splitted = data.split(",");
    this.uuid = splitted[0];
    this.name = splitted[1];
    this.group = splitted[2];
    this.period = int.parse(splitted[3]);

    List<String> diatomicElements = new List<String>();
    diatomicElements = ["H", "O", "N", "I", "F", "Cl", "Br"];

    for (int i = 0; i < diatomicElements.length; i++) {
      if (this.name == diatomicElements[i]) {
        isDiatomic = true;
      }
    }
  }

  Container draw(double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: width * 0.01),
        color: usedInReaction ? secondaryYellow : Colors.white,
      ),
      child: Column(
        children: <Widget>[
          //Group
          Container(
            height: height * 0.3,
            width: width,
            child: Text(group),
            margin: EdgeInsets.only(right: width * 0.1, top: height * 0.02),
            alignment: Alignment.topRight,
          ),

          //Name
          Container(
            height: height * 0.3,
            width: width,
            child: getNameAsTextWidget(height * 0.25),
//            child: Row(
//              mainAxisAlignment: MainAxisAlignment.center,
//              crossAxisAlignment: CrossAxisAlignment.center,
//              children: <Widget>[
//                Text(
//                  name,
//                  style: TextStyle(
//                      fontWeight: FontWeight.bold, fontSize: height * 0.25),
//                ),
//                Container(
//                  child: isDiatomic
//                      ? Text("2",
//                          style: TextStyle(
//                              fontSize: height * 0.125,
//                              fontWeight: FontWeight.bold))
//                      : Container(
//                          width: 0,
//                          height: 0,
//                        ),
//                  alignment: Alignment.bottomCenter,
//                )
//              ],
//            ),
            alignment: Alignment.center,
          ),

          //Period
          Container(
            height: height * 0.3,
            width: width,
            child: Text(period.toString()),
            margin: EdgeInsets.only(left: width * 0.1),
            alignment: Alignment.bottomLeft,
          )
        ],
      ),
    );
  }

  Draggable drawDraggableElementCard(double width, double height) {
    return Draggable<ElementCard>(
      data: this,
      child: this != null
          ? this.draw(width, height)
          : Container(
              width: width,
              height: height,
              color: Colors.blueGrey,
            ),
      feedback: this != null
          ? Material(child: this.draw(width, height))
          : Container(
              width: width,
              height: height,
              color: Colors.blueGrey,
            ),
      childWhenDragging: Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      onDragCompleted: () {},
    );
  }

  Draggable drawDraggableCard(double width, double height) {
    return Draggable<card>(
      data: this,
      child: this != null
          ? this.draw(width, height)
          : Container(
              width: width,
              height: height,
              color: Colors.blueGrey,
            ),
      feedback: this != null
          ? Material(child: this.draw(width, height))
          : Container(
              width: width,
              height: height,
              color: Colors.blueGrey,
            ),
      childWhenDragging: Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      onDragCompleted: () {},
    );
  }

  @override
  Row getNameAsTextWidget(double height) {
    if (isDiatomic) {
      return Row(
        children: <Widget>[
          Text(name, style: TextStyle(fontSize: height)),
          Container(
            child: Text("2",
                style: TextStyle(
                  fontSize: height / 2,
                  fontWeight: FontWeight.bold,
                )),
            alignment: Alignment.bottomCenter,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      );
    } else {
      return Row(
        children: <Widget>[
          Text(name,
              style: TextStyle(fontSize: height, fontWeight: FontWeight.bold))
        ],
        mainAxisAlignment: MainAxisAlignment.center,
      );
    }
  }
}
