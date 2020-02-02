import 'package:chemistry_game/models/card.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:uuid/uuid.dart';

class Reaction {

  //final ReactionType reactionType;
  int leftSide; //Can be removed if they are not used
  int rightSide;

  Map<Uuid, card> leftSideCards = new Map<Uuid, card>(); //Can be changed to Multimap
  Map<Uuid, card> rightSideCards = new Map<Uuid, card>();

  ValueNotifier<bool> updated = new ValueNotifier<bool>(false);
  //ValueNotifier<bool> showEditMenu = new ValueNotifier<bool>(false);

  /*Reaction(this.reactionType) {
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
  }*/

  Reaction();

  /*void addProduct(card card) {
    //TODO: Validation
    rightSideCards[card.uuid] = card;
    //rightSideCards[index] = elementCard;
  }

  void addReactant(card card) {
    //TODO: Validation
    //leftSideCards[index] = elementCard;
    leftSideCards[card.uuid] = card;
  }*/

  Widget draw(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Row(
        children: <Widget>[
          ValueListenableBuilder(
            valueListenable: updated,
            builder: (BuildContext context, bool value, child) {
              return Expanded(
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    //drawCompleteButton(width, height),
                    //drawEditButton(width, height),
                    drawLeftSide(width, height),
                    drawLeftSideAddCardButton(width * 0.1, height * 0.7),
                    drawArrow(width * 0.1, height * 0.7),
                    drawRightSide(width, height),
                    drawRightSideAddCardButton(width * 0.1, height * 0.7),
                  ],
                ),
              );
            },
            child: Expanded(
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: <Widget>[
                  //drawCompleteButton(width, height),
                  //drawEditButton(width, height),
                  drawLeftSide(width, height),
                  drawLeftSideAddCardButton(width * 0.1, height * 0.7),
                  drawArrow(width * 0.1, height * 0.7),
                  drawRightSide(width, height),
                  drawRightSideAddCardButton(width * 0.1, height * 0.7),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Container drawLeftSide(double width, double height) {

    List<Widget> leftSideWidgets = new List<Widget>();

    /*for(int i = 0; i < leftSideCards.length; i++) {
      leftSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, leftSideCards.values[i]));
      if(i+1 != leftSideCards.length) {
        leftSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
      } //Add "plus"
    }*/

    leftSideCards.forEach((key, value) {
      leftSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, key, value));
      leftSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
    });

    if(leftSideWidgets.length > 0) leftSideWidgets.removeLast();

    return Container(
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: leftSideWidgets,
      ),
    );
  }

  Widget drawLeftSideAddCardButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: IconButton(
        icon: Icon(Icons.add),
        onPressed: () {
          var newId = new Uuid();
          leftSideCards[newId] = null;
          updated.value = !updated.value;
        },
      ),
    );
  }

  Container drawRightSide(double width, double height) {

    List<Widget> rightSideWidgets = new List<Widget>();

    /*for(int i = 0; i < rightSideCards.length; i++) {
      rightSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, rightSideCards[i])); //Add rectangle with either the value of the reactant or empty
      //print(rightSideCards[i].name);
      if(i+1 != rightSideCards.length) {
        rightSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
        print(drawPlus(width, height));
      } //Add "plus"
    }*/

    rightSideCards.forEach((key, value) {
      rightSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, key,  value));
      rightSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
    });

    if(rightSideWidgets.length > 0) rightSideWidgets.removeLast();

    return Container(
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: rightSideWidgets,
      ),
    );
  }

  Widget drawRightSideAddCardButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: IconButton(
        icon: Icon(Icons.add),
        onPressed: () {
          var newId = new Uuid();
          rightSideCards[newId] = null;
          updated.value = !updated.value;
        },
      ),
    );
  }

  Container drawCardPlace(double width, double height, Uuid uuid, card card) {
    return Container(
      width: width,
      height: height,
      child: card != null ? drawCard(width, height, uuid, card) : drawCard(width, height, uuid, card),
      decoration: BoxDecoration(
        border: new Border.all(
          width: 1,
        ),

      ),
    );
  }

  Widget drawCard(double width, double height, Uuid uuid ,card card) { //TODO: delete card card
    return Container(
      width: width,
      height: height,
      child: Column(
        children: <Widget>[
          Container(
            width: width,
            height: height * 0.2,

            child: RaisedButton(
              onPressed: () {
                if(leftSideCards.containsKey(uuid)) {
                  leftSideCards.remove(uuid);
                } else if(rightSideCards.containsKey(uuid)) {
                  rightSideCards.remove(uuid);
                } else{
                  print("Error, invalid data in drawCard");
                }

                updated.value = !updated.value;
              },
              child: Text("delete")
            ),
          ),
          card != null ? Container(
            child: Center(
              child: Text(card.name),
            )
          ) : drawEmptyCardDragTarget(width, height * 0.77, uuid),//TODO: check the height
        ],
      ),
    );
  }

  Widget drawEmptyCardDragTarget(double width, double height, Uuid uuid) {
    return Container(
      width: width,
      height: height,
      child: DragTarget<card>(
        builder: (BuildContext context, List<card> incoming, rejected) {
          return Container(
            color: Colors.blue
          );
        },

        onWillAccept: (data) => data != null,

        onAccept: (data) {
          if(leftSideCards.containsKey(uuid)) {
            leftSideCards[uuid] = data;
          } else if(rightSideCards.containsKey(uuid)) {
            rightSideCards[uuid] = data;
          }
          updated.value = !updated.value;
        },

        onLeave: (data) {

        },
      ),
    );
  }

  Widget drawPlus(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Icon(LineIcons.plus)
    );
  }

  Widget drawArrow(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Icon(LineIcons.long_arrow_right),
    );
  }

  void clear() {
    leftSideCards.clear();
    rightSideCards.clear();

    updated.value = !updated.value;
  }
}

enum ReactionType {
  Combination,
  Decomposition,
  DisplacementReaction,
  DoubleDisplacementReaction,
  CombustionReaction
}