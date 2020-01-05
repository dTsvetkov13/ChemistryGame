//TODO: Rename this class to "reaction_card" (i'm not sure)

import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class CombinationCard extends card{
  final String name;

  CombinationCard({this.name});

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
        data: CombinationCard(name: name),
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