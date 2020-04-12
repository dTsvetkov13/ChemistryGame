import 'package:chemistry_game/models/card.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:line_icons/line_icons.dart';
import 'package:uuid/uuid.dart';

class Reaction {

  Map<Uuid, card> leftSideCards = new Map<Uuid, card>();
  Map<Uuid, card> rightSideCards = new Map<Uuid, card>();

  ValueNotifier<bool> updated = new ValueNotifier<bool>(false);
  ValueNotifier<bool> exists = new ValueNotifier<bool>(false);

  Reaction();

  Widget draw(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: ValueListenableBuilder(
        valueListenable: updated,
        builder: (BuildContext context, bool value, child) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                drawLeftSide(width, height),
                Container(
                  width: width / 64,
                ),
                drawLeftSideAddCardButton(width * 5 / 32, height * 5 / 16),
                drawArrow(width * 0.1, height * 0.7),
                drawRightSide(width, height),
                Container(
                  width: width / 64,
                ),
                drawRightSideAddCardButton(width * 5 / 32, height * 5 / 16),
              ],
            ),
          );
        },
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: <Widget>[
              drawLeftSide(width, height),
              Container(
                width: width / 64,
              ),
              drawLeftSideAddCardButton(width * 5 / 32, height * 5 / 16),
              drawArrow(width * 0.1, height * 0.7),
              drawRightSide(width, height),
              Container(
                width: width / 64,
              ),
              drawRightSideAddCardButton(width * 5 / 32, height * 5 / 16),
            ],
          ),
        )
      ),
    );
  }

  Container drawLeftSide(double width, double height) {

    List<Widget> leftSideWidgets = new List<Widget>();

    leftSideCards.forEach((key, value) {
      leftSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, key, value));
      leftSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
    });

    if(leftSideWidgets.length > 0) leftSideWidgets.removeLast();

    return Container(
      child: Row(
        children: leftSideWidgets,
      ),
    );
  }

  Widget drawLeftSideAddCardButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.lightGreenAccent,
      child: RaisedButton(
        child: Text("add"),
        color: primaryGreen,
        onPressed: () {
          exists.value = true;
          var newId = new Uuid();
          leftSideCards[newId] = null;
          updated.value = !updated.value;
        },
      ),
    );
  }

  Container drawRightSide(double width, double height) {

    List<Widget> rightSideWidgets = new List<Widget>();

    rightSideCards.forEach((key, value) {
      rightSideWidgets.add(drawCardPlace(width * 0.1, height * 0.7, key,  value));
      rightSideWidgets.add(drawPlus(width * 0.05, height * 0.7));
    });

    if(rightSideWidgets.length > 0) rightSideWidgets.removeLast();

    return Container(
      child: Row(
        children: rightSideWidgets,
      ),
    );
  }

  Widget drawRightSideAddCardButton(double width, double height) {
    return Container(
      width: width,
      height: height,
      child: RaisedButton(

        child: Text(
          "add"
        ),
      color: primaryGreen,
      onPressed: () {
        exists.value = true;
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

                if(leftSideCards.length == 0 && rightSideCards.length == 0) {
                  exists.value = false;
                }


                if(card != null ) card.usedInReaction = false;

                updated.value = !updated.value;
              },
              child: Center(child: Text("X"))
            ),
          ),
          card != null ? Container(
            width: width,
            height: height * 0.77,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                card.getNameAsTextWidget(height * 0.15),
              ],
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

        onWillAccept: (data) => (data != null) && !data.usedInReaction,

        onAccept: (data) {
          if(leftSideCards.containsKey(uuid)) {
            leftSideCards[uuid] = data;
          } else if(rightSideCards.containsKey(uuid)) {
            rightSideCards[uuid] = data;
          }

          data.usedInReaction = true;

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

    leftSideCards.values.forEach((card) {
      if(card != null) {
        card.usedInReaction = false;
      }
    });

    rightSideCards.values.forEach((card) {
      if(card != null) {
        card.usedInReaction = false;
      }
    });

    leftSideCards.clear();
    rightSideCards.clear();
    exists.value = false;

    updated.value = !updated.value;
  }
}