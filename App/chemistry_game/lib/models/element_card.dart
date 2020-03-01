import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class ElementCard extends card{
  String name;
  String group;
  int period;

  ElementCard({this.name, this.group, this.period}) {
    //TODO: check name for H, 0, I, etc... and change them to H2, etc
  }

  ElementCard.fromString(String data){
    var splitted = data.split(",");
    this.uuid = splitted[0];
    this.name = splitted[1];
    this.group = splitted[2];
    this.period = int.parse(splitted[3]);
  }

  Container draw(double width, double height) {
    return Container(
      height: height,
      width: width,

      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: width * 0.01
          ),
          color: usedInReaction ? secondaryYellow : Colors.white,
      ),
      child: Column(
        children: <Widget>[

          //Group
          Container(
            height: height * 0.3,
            width: width,
            child: Text(group),
            margin: EdgeInsets.only(right: width * 0.1, top: height * 0.05),
            alignment: Alignment.topRight,

          ),

          //Name
          Container(
            height: height * 0.3,
            width: width,
            child: Text(
              name,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: height * 0.2),
            ),
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
      child: this != null ? this.draw(width, height) : Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      feedback: this != null ? Material(child: this.draw(width, height)) : Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      childWhenDragging: Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      onDragCompleted: () {

      },
    );
  }

  Draggable drawDraggableCard(double width, double height) {
    return Draggable<card>(
      data: this,
      child: this != null ? this.draw(width, height) : Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      feedback: this != null ? Material(child: this.draw(width, height)) : Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      childWhenDragging: Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      onDragCompleted: () {

      },
    );
  }
}