import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class CompoundCard extends card{
  final String name;

  CompoundCard({this.name});

  Container draw(double width, double height){
    return Container(
      width: width * 0.97,
      height: height * 0.97,
      child: Center(child: Text(name)),
      decoration: BoxDecoration(
          border: Border.all(width: width * 0.03)
      ),
    );
  }

  Widget drawDraggable(double width, double height) {
    return Container(
        width: width * 0.97,
        height: height * 0.97,
        decoration: BoxDecoration(
            border: Border.all(width: width * 0.03)
        ),
        child: Draggable<card>(
          data: CompoundCard(name: name),
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
        )

    );
  }
}