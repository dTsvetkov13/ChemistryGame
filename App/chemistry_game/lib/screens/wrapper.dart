import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chemistry_game/models/User.dart';
import 'package:chemistry_game/screens/home/home.dart';
import 'package:chemistry_game/screens/authenticate/authenticate.dart';

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {

    final user = Provider.of<User>(context);

    print('First user - ${user}');

    if(user == null) {
      return Authenticate();
    }
    else {
      print('Second user - ${user.uid}');
      return HomeScreen();
    }
  }
}