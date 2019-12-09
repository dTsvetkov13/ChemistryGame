import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';


class Authenticate extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return AuthenticateState();
  }
}

class AuthenticateState extends State<Authenticate> {

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final buttonWidth = mediaQueryData.size.width * 0.35;
    final buttonHeight = mediaQueryData.size.height*0.06;

    return Scaffold(
      appBar: AppBar(
        title: Text("Registration Form"),
      ),
      body: Center(
        child: Column( //TODO: Change Column with another widget, maybe Row
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget> [

            Container(
              margin: EdgeInsets.all(5.0),
              child: SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: RaisedButton (
                  child: Text("Login"),
                  //padding: EdgeInsets.symmetric(horizontal: (mediaQueryData.size.width/10)*3.5, vertical: mediaQueryData.size.height*(0.03)),
                  //padding: EdgeInsets.only(right: mediaQueryData.size.width/3, bottom: mediaQueryData.size.height/5),
                  onPressed: () {
                    print("Login pressed");
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen())
                    );
                  }
                ),
              ),
            ),

            Container(
              margin: EdgeInsets.all(5.0),
              child: SizedBox(
                height: buttonHeight,
                width: buttonWidth,
                child: RaisedButton(
                  child: Text("Register"),
                  //padding: EdgeInsets.symmetric(horizontal: (mediaQueryData.size.width/10)*3.5, vertical: mediaQueryData.size.height*(0.03)),
                  onPressed: () {
                    print("Register pressed");
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterScreen())
                    );
                  }
                ),
              ),
            ),
          ]
        )
      )
    );
  }
}

