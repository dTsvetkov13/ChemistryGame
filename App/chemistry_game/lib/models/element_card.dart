import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class ElementCard extends card{
  //TODO: add id - uuid
  final String name;
  final String group;
  final int period;

  ElementCard({this.name, this.group, this.period});

  Container draw(double width, double height) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
          border: Border.all(
            color: Colors.black,
            width: width * 0.01
          ),

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
    return Draggable<card>(
      data: ElementCard(name: name, group: group, period: period),
      child: this != null ? this.draw(width, height) : Container(
        width: width,
        height: height,
        color: Colors.blueGrey,
      ),
      feedback: this != null ? this.draw(width, height) : Container(
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