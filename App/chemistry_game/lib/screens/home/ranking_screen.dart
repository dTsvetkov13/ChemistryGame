import 'package:flutter/material.dart';
import 'package:chemistry_game/constants/text_styling.dart';

class RankingScreen extends StatefulWidget {
  @override
  _RankingScreenState createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  @override
  Widget build(BuildContext context) {
    return Text(
      'Index 3: Ranking',
      style: optionStyle,
    );
  }
}
