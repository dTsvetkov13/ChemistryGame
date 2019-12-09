import 'package:flutter/material.dart';
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

class Wrapper extends StatefulWidget {
  @override
  _WrapperState createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {

    final user = Provider.of<User>(context);

    print('First user - $user');

    if(user == null) {
      return Authenticate();
    }
    else {
      print('Second user - $user');
      return HomeScreen();
    }
  }
}
