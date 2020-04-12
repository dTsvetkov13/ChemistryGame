import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/models/card.dart';

class CompoundCard extends card {
  String name;

  CompoundCard({this.name});

  CompoundCard.fromString(String data) {
    var splitted = data.split(",");
    this.name = splitted[0];
    this.uuid = splitted[1];
  }

  Container draw(double width, double height) {
    return Container(
      width: width * 0.97,
      height: height * 0.97,
      child: Center(
        child: getNameAsTextWidget(height * 0.15),
      ),
      //child: Text(name, style: TextStyle(fontWeight: FontWeight.bold))),
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
        decoration: BoxDecoration(border: Border.all(width: width * 0.01)),
        child: Draggable<card>(
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
        ));
  }

  @override
  Row getNameAsTextWidget(double height) {
    List<Widget> list = new List<Widget>();
    String string = "";

    for (int i = 0; i < name.length; i++) {
      if (int.tryParse(name[i]) != null) {
        list.add(Text(string,
            style: TextStyle(fontSize: height, fontWeight: FontWeight.bold)));
        list.add(Container(
          height: height,
          child: Text(name[i],
              style:
                  TextStyle(fontSize: height / 2, fontWeight: FontWeight.bold)),
          alignment: Alignment.bottomCenter,
        ));
        string = "";
      } else {
        string += name[i];
      }
    }

    if (string != "")
      list.add(Text(string,
          style: TextStyle(fontSize: height, fontWeight: FontWeight.bold)));

    return Row(
      children: list,
      mainAxisAlignment: MainAxisAlignment.center,
    );
  }
}
