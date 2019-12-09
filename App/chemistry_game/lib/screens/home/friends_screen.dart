import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';

class FriendsScreen extends StatefulWidget {
  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Index 2: Friends',
      style: optionStyle,
    );
  }
}
