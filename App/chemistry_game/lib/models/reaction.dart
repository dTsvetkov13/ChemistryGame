import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'element_card.dart';

class Reaction {

  final ReactionType reactionType;
  int leftSide; //Can be removed if they are not used
  int rightSide;
  List<ElementCard> leftSideCards;
  List<ElementCard> rightSideCards;
  ValueNotifier<bool> showEdinMenu = new ValueNotifier<bool>(false);

  Reaction(this.reactionType) {
    switch (reactionType) {
      case (ReactionType.Combination):
        leftSide = 2;
        rightSide = 1;
        leftSideCards = new List(2);
        rightSideCards = new List(1);
        break;
      case (ReactionType.Decomposition) :
        leftSide = 1;
        rightSide = 2;
        leftSideCards = new List(1);
        rightSideCards = new List(2);
        break;
      /*case (ReactionType.DisplacementReaction) : //TODO: check the values in the different types
        leftSide = 1;
        rightSide = 2;
        break;
      case (ReactionType.DoubleDisplacementReaction) :
        leftSide = 1;
        rightSide = 2;
        break;
      case (ReactionType.CombustionReaction) :
        leftSide = 1;
        rightSide = 2;
        break;*/
      default: print("There is no such case");
    }
  }

  void addProduct(int index, ElementCard elementCard) {
    rightSideCards[index] = elementCard;
  }

  void addReactant(int index, ElementCard elementCard) {
    leftSideCards[index] = elementCard;
  }

  Widget draw(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: <Widget>[
                //drawCompleteButton(width, height),
                //drawEditButton(width, height),
                drawLeftSide(width, height),
                drawArrow(width, height), //TODO: check the name of the specific arrow
                drawRightSide(width, height),
              ],
            ),
          ),
          //drawDeleteButton(width, height)
        ],
      ),
    );
  }

  Container drawLeftSide(double width, double height) {

    List<Widget> leftSideWidgets = new List<Widget>();

    for(int i = 0; i < leftSideCards.length; i++) {
      leftSideWidgets.add(drawCardPlace(width, height, leftSideCards[i])); //Add rectangle with either the value of the reactant or empty
      if(i+1 != leftSideCards.length) {
        leftSideWidgets.add(drawPlus(width, height));
      } //Add "plus"
    }

    return Container(
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: leftSideWidgets,
      ),
    );

  }

  Container drawRightSide(double width, double height) {

    List<Widget> rightSideWidgets = new List<Widget>();

    for(int i = 0; i < rightSideCards.length; i++) {
      rightSideWidgets.add(drawCardPlace(width, height, rightSideCards[i])); //Add rectangle with either the value of the reactant or empty
      print(rightSideCards[i].name);
      if(i+1 != rightSideCards.length) {
        rightSideWidgets.add(drawPlus(width, height));
        print(drawPlus(width, height));
      } //Add "plus"
    }

    return Container(
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rightSideWidgets,
      ),
    );

  }

  Container drawCardPlace(double width, double height, ElementCard elementCard) {
    return Container(
      width: width * 0.1,
      height: height * 0.7,
      child: elementCard != null ? Center(child: Text(elementCard.name)) : Text(""),
      decoration: BoxDecoration(
        border: new Border.all(
          width: 1,
        ),

      ),
    );
  }

  Widget drawPlus(double width, double height) {
    return Container(
      width: width * 0.05,
      height: height * 0.7,
      child: Icon(LineIcons.plus)
    );
  }

  Widget drawArrow(double width, double height) {
    return Container(
      width: width * 0.1,
      height: height * 0.7,
      child: Icon(LineIcons.long_arrow_right),
    );
  }
}

enum ReactionType {
  Combination,
  Decomposition,
  DisplacementReaction,
  DoubleDisplacementReaction,
  CombustionReaction
}