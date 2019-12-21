import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chemistry_game/models/User.dart';
import 'package:chemistry_game/screens/authenticate/authenticate.dart';
import 'package:chemistry_game/screens/wrapper.dart';
import 'package:chemistry_game/services/auth.dart';
import 'package:chemistry_game/screens/home/home.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    return StreamProvider<User>.value(
      value: AuthService().user,
      child: MaterialApp(
        title: 'Authention Menu',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        //home: Wrapper(),
        home: Wrapper(),
      ),
    );
  }
}
