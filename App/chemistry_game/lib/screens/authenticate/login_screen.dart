import 'package:flutter/material.dart';
import 'package:chemistry_game/services/auth.dart';

class LoginScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return LoginForm();
  }
}

class LoginForm extends State<LoginScreen> {

  final AuthService _auth = AuthService();
  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;

  String email = '';
  String password = '';
  String error = '';

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

        appBar: AppBar(
            title: Text("Login Form")
        ),
        backgroundColor: Colors.blueAccent,
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.all(_minimumPadding * 2),
            child: ListView(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(
                      top: _minimumPadding, bottom: _minimumPadding),

                  child: TextFormField(
                    keyboardType: TextInputType.emailAddress,
                    controller: usernameController,
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
                            color: Colors.yellowAccent,
                            fontSize: 15.0
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                      top: _minimumPadding, bottom: _minimumPadding),

                  child: TextFormField(
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
                            color: Colors.yellowAccent,
                            fontSize: 15.0
                        ),

                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        )
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(
                    bottom: _minimumPadding, top: _minimumPadding),
                  child: RaisedButton(
                    child: Text(
                      'Login',
                      textScaleFactor: 1.5,
                    ),
                    onPressed: () async {
                      if(_formKey.currentState.validate()){
                        //setState(() => loading = true);
                        dynamic result = await _auth.signInWithEmailAndPassword(email, password);
                        if(result == null) {
                          setState(() {
                            //loading = false;
                            error = 'Could not sign in with those credentials';
                          });
                        } else {
                          print(result);
                          Navigator.pop(context);
                        }
                      }
                    }
                  )
                )
              ],
            ),
          ),
        )

    );
  }

/*void login(DocumentSnapshot snapshot, String username, String password) {

    User user = User.fromSnapshot(snapshot);

    print(user.username + " - " + user.password);

    if(user.username == username) {
      if (user.password == password){
        print("Logged in");
      }
    }

    print("Fault");
  }

  bool isLogged() {
    String currUsername = usernameController.text;
    String currPassword = passwordController.text;
    User user;
    var snapshots = Firestore.instance.collection('users').snapshots();

    snapshots.map((data) => {

      data.documents.map( (snapshot) =>
      {
        login(snapshot, currUsername, currPassword)
      })
        }
    );

    //String user1 = "Ivan";
    usernameController.text = "";
    passwordController.text = "";

    /*if (currUsername == user){
      print(currUsername);
      return true;
    }
    else {*/
    return false;
  }
}*/
}