import 'package:chemistry_game/services/auth.dart';
import 'package:chemistry_game/services/database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:nice_button/nice_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';


class Authenticate extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return AuthenticateState();
  }
}

class AuthenticateState extends State<Authenticate> {

  bool loginAreaFirstChild = true;
  bool registerAreaFirstChild = true;
  bool informationAreaFirstChild = true;

  final AuthService _auth = AuthService();
  var _loginFormKey = GlobalKey<FormState>();
  var _registerFormKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  var error = new ValueNotifier<String>("");
  String username = '';

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  final ScrollController controller = ScrollController();

  @override
  Widget build(BuildContext context) {

    final mediaQueryData = MediaQuery.of(context);
    final height = mediaQueryData.size.height;
    final width = mediaQueryData.size.width;
    final buttonWidth = mediaQueryData.size.width * 0.4;
    final buttonHeight = mediaQueryData.size.height * 0.15;

    return Scaffold(
      resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            Positioned.fill(
              child: Opacity(
                opacity: 0.05,
                child: DecoratedBox(
                  position: DecorationPosition.background,
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage("images/background4.png"),
                          fit: BoxFit.cover
                      )
                  ),
                ),
              ),
            ),
            Center(
            child: Container(
              width: width * 0.4,
              height: height * 0.7,
//            color: Colors.blueGrey,
              child: Center(
                  child: ListView(
                    scrollDirection: Axis.vertical,
                    children: <Widget> [
                      ValueListenableBuilder(
                        valueListenable: error,
                        child: Text(error.value),
                        builder: (BuildContext context, String value , Widget child) {
                          return Text(error.value);
                        }
                      ),
                      loginStateChangeButton(buttonWidth, buttonHeight),
                      loginArea(width * 0.4, height * 0.35),
                      registerStateChangeButton(buttonWidth, buttonHeight),
                      registerArea(width * 0.4, height * 0.35),
                      informationStateChangeButton(buttonWidth, buttonHeight),
                      //TODO: add informationArea
                    ]
                  )
              ),
            ),
          ),
          ]
        )
    );

  }

  Widget loginStateChangeButton(double width, double height) {
    return Container(
      margin: EdgeInsets.all(5.0),
      child: SizedBox(
        height: height,
        width: width,
        child: NiceButton (
          width: width,
          elevation: 8.0,
          radius: 52.0,
          background: Colors.blue,
          textColor: Colors.black,
          text: "Login",
          onPressed: () {
            print("Login pressed");
            setState(() {
              loginAreaFirstChild = !loginAreaFirstChild;
            });
          }
        ),
      ),
    );
  }



  Widget loginArea(double width, double height) {
    return AnimatedCrossFade(
      duration: Duration(seconds: 1),
      firstChild: Container(width: 0, height: 0,),
      secondChild: loginForm(height),
      crossFadeState: loginAreaFirstChild ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }

  Form loginForm(double height) {
    return Form(
      key: _loginFormKey,
      child: Container(
        height: height,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            TextFormField(
              keyboardType: TextInputType.text,
              controller: usernameController,
              validator: (val) => val.isEmpty ? 'Enter your username' : null,
              onChanged: (val) {
                setState(() {
                  username = val;
                });
              },

              decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Please enter your username",
                  errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  )
              ),
            ),
            TextFormField(
              keyboardType: TextInputType.text,
              controller: passwordController,
              obscureText: true,
              validator: (val) => val.length < 6 ? 'Please enter a password longer than 6 chars' : null,

              onChanged: (val) {
                setState(() {
                  password = val;
                });
              },

              decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Please enter your password",
                  errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  )
              ),
            ),
            RaisedButton(
              child: Text(
                'Login',
                textScaleFactor: 1.5,
              ),
              onPressed: () async {
                if(_loginFormKey.currentState.validate()){
                  try {
                    dynamic result = await _auth.signInWithEmailAndPassword(username + "@domain.com", password);
                    print(result.uid);
                  }
                  catch(error) {
                    print(error.code.toString());
                    switch (error.code) {
                      case "ERROR_INVALID_EMAIL":
                        this.error.value = "Your email address appears to be malformed.";
                        break;
                      case "ERROR_WRONG_PASSWORD":
                        this.error.value = "Your password is wrong.";
                        break;
                      case "ERROR_USER_NOT_FOUND":
                        this.error.value = "User with this username doesn't exist.";
                        break;
                      case "ERROR_USER_DISABLED":
                        this.error.value = "User with this username has been disabled.";
                        break;
                      case "ERROR_TOO_MANY_REQUESTS":
                        this.error.value = "Too many requests. Try again later.";
                        break;
                      case "ERROR_OPERATION_NOT_ALLOWED":
                        this.error.value = "Signing in with Username and Password is not enabled.";
                        break;
                      default:
                        this.error.value = "An undefined Error happened.";
                    }
                  }
                }
              }
            )
          ],
        ),
      ),
    );
  }

  Widget registerStateChangeButton(double width, double height) {
    return Container(
      margin: EdgeInsets.all(5.0),
      child: SizedBox(
        height: height,
        width: width,
        child: NiceButton(
            width: width,
            elevation: 8.0,
            radius: 52.0,
            background: Colors.blue,
            textColor: Colors.black,
            text: "Register",
            //padding: EdgeInsets.symmetric(horizontal: (mediaQueryData.size.width/10)*3.5, vertical: mediaQueryData.size.height*(0.03)),
            onPressed: () {
              print("Register pressed");
              setState(() {
                registerAreaFirstChild = !registerAreaFirstChild;
              });
            }
        ),
      ),
    );
  }

  Widget registerArea(double width, double height) {
    return AnimatedCrossFade(
      duration: Duration(seconds: 1),
      firstChild: Container(width: 0, height: 0,),
      secondChild: registerForm(height, width),
      crossFadeState: registerAreaFirstChild ? CrossFadeState.showFirst : CrossFadeState.showSecond,
    );
  }

  Form registerForm(double height, double width) {
    return Form(
      key: _registerFormKey,
      child: Container(
        height: height,
        child: ListView(
          scrollDirection: Axis.vertical,
          children: <Widget>[
            TextFormField(
              keyboardType: TextInputType.text,
              controller: usernameController,
              validator: (val) => val.isEmpty ? 'Enter an username' : null,
              onChanged: (val) {
                setState(() {
                  username = val;
                });
              },

              decoration: InputDecoration(
                  labelText: "Username",
                  hintText: "Please enter your username",
                  errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  )
              ),
            ),
            TextFormField(
              keyboardType: TextInputType.emailAddress,
              controller: emailController,
              validator: (val) => val.isEmpty ? 'Enter an email' : null,
              onChanged: (val) {
                setState(() {
                  email = val;
                });
              },

              decoration: InputDecoration(
                  labelText: "Email",
                  hintText: "Please enter your email",
                  errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  )
              ),
            ),
            TextFormField(
              keyboardType: TextInputType.text,
              controller: passwordController,
              obscureText: true,
              validator: (val) => val.length < 6 ? 'Please enter a password longer than 6 chars' : null,

              onChanged: (val) {
                setState(() {
                  password = val;
                });
              },

              decoration: InputDecoration(
                  labelText: "Password",
                  hintText: "Please enter your password",
                  errorStyle: TextStyle(
                      color: Colors.red,
                      fontSize: 15.0
                  ),

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  )
              ),
            ),
            NiceButton(
              width: width,
              elevation: 8.0,
              background: Colors.blue,
              textColor: Colors.black,
//              radius: 52.0,
              text: "Register",
                onPressed: () async {
                  if(_registerFormKey.currentState.validate()){
                    try {
                      dynamic result = await _auth.registerWithEmailAndPassword(username + "@domain.com", password);
                      print(result.uid);
                      DatabaseService(result.uid).configureUser(username, email);
                      Navigator.pop(context);
                    }
                    catch(error) {
                      print(error);
                      switch (error.code) {
                        case "ERROR_EMAIL_ALREADY_IN_USE":
                          this.error.value = "This username is already used";
                          break;
                        default:
                          this.error.value = "An undefined error happened.";
                      }
                    }
                  }
                }
            )
          ]
        ),
      )
    );
  }

  Widget informationStateChangeButton(double width, double height) {
    return Container(
      margin: EdgeInsets.all(5.0),
      child: SizedBox(
        height: height,
        width: width,
        child: NiceButton (
            width: width,
            elevation: 8.0,
            radius: 52.0,
            background: Colors.blue,
            textColor: Colors.black,
            text: "Information",
            //padding: EdgeInsets.symmetric(horizontal: (mediaQueryData.size.width/10)*3.5, vertical: mediaQueryData.size.height*(0.03)),
            //padding: EdgeInsets.only(right: mediaQueryData.size.width/3, bottom: mediaQueryData.size.height/5),
            onPressed: () {
              print("Information pressed");
              //TODO: Change the state of the AnimatedFade
            }
        ),
      ),
    );
  }

  Widget informationArea(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.blue,
    );
  }
}