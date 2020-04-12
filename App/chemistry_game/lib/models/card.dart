import 'package:flutter/cupertino.dart';

abstract class card {
  String uuid;
  String name;
  bool usedInReaction = false;
  bool seen = false;

  Row getNameAsTextWidget(double height);
}