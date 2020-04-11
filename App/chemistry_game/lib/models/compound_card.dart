import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class CompoundCard extends card{
  String name;

  CompoundCard({this.name});
  CompoundCard.fromString(String data){
    var splitted = data.split(",");
    this.name = splitted[0];
    this.uuid = splitted[1];
  }

  Container draw(double width, double height){
    return Container(
      width: width * 0.97,
      height: height * 0.97,
      child: Center(child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
      decoration: BoxDecoration(
        border: Border.all(width: width * 0.01),
        color: usedInReaction ? secondaryYellow : Colors.white,
      ),
    );
  }

  Widget drawDraggable(double width, double height) {
    return Container(
        width: width * 0.97,
        height: height * 0.97,
        decoration: BoxDecoration(
            border: Border.all(width: width * 0.01)
        ),
        child: Draggable<card>(
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
        )

    );
  }
}