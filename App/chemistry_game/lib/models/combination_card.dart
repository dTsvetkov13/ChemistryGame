import 'package:flutter/material.dart';

class CombinationCard {
  final String name;

  CombinationCard({this.name});

  Container draw(double width, double height){
    return Container(
      width: width * 0.97,
      height: height * 0.97,
      child: Center(child: Text(name)),
      decoration: BoxDecoration(
        border: Border.all(width: width * 0.97)
      ),

    );
  }
}