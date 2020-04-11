import 'package:chemistry_game/models/remote_config.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
  void initState() {
    // TODO: implement initState
    super.initState();
    Config().getAllData();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Config().gotData,
      child: Container(),
      builder: (BuildContext context, bool value, Widget chikd) {
        if(value) {
          final user = Provider.of<User>(context);

          if(user == null) {
            return Authenticate();
          }
          else {
            print('user - ${user.uid}');
            return HomeScreen();
          }
        }
        else {
          return Container(
            color: primaryGreen,
            child: SpinKitFadingCircle(
              color: Colors.white,
            ),
          );
        }
      },
    );
  }
}