import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';

ThemeData appTheme() {

  hexStringToHexInt(String hex) {
    hex = hex.replaceFirst('#', '');
    hex = hex.length == 6 ? 'ff' + hex : hex;
    int val = int.parse(hex, radix: 16);
    return val;
  }

  var textColor = Color(hexStringToHexInt("#3C4054"));
  
  return ThemeData(

    primaryColor: primaryGreen, //green
    accentColor: primaryPurple, //light purple
    textSelectionColor: textColor, //black
    buttonColor: secondaryPurple,
    buttonTheme: ButtonThemeData(
      buttonColor: secondaryPurple,
    )
  );
}