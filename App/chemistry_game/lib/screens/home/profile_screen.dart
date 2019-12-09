import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Index 1: Profile',
      style: optionStyle,
    );
  }
}