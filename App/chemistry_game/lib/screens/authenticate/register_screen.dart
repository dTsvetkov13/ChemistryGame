import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:chemistry_game/models/User.dart';
import 'package:chemistry_game/services/auth.dart';
import 'package:chemistry_game/services/database.dart';

class RegisterScreen extends StatefulWidget{

  @override
  State<StatefulWidget> createState() {
    return RegisterForm();
  }
}

class RegisterForm extends State<RegisterScreen> {

  final AuthService _auth = AuthService();
  var _formKey = GlobalKey<FormState>();
  final double _minimumPadding = 5.0;

  String email = '';
  String password = '';
  String error = '';
  String username = '';

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register Form"),
      ),
      backgroundColor: Colors.blueAccent,
      body: Form(
        key: _formKey,

        child: Padding(
          padding: EdgeInsets.all(_minimumPadding * 2),
          child: ListView(
            children: <Widget>[

              Padding(
                padding: EdgeInsets.only(top: _minimumPadding, bottom: _minimumPadding),

                child: TextFormField(
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
                padding: EdgeInsets.only(top: _minimumPadding, bottom: _minimumPadding),

                child: TextFormField(
                  keyboardType: TextInputType.text,
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
                padding: EdgeInsets.only(top: _minimumPadding, bottom: _minimumPadding),

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
                  padding: EdgeInsets.only(bottom: _minimumPadding, top: _minimumPadding),
                  child: RaisedButton(
                      child: Text(
                        'Register',
                        textScaleFactor: 1.5,
                      ),

                      onPressed: () async {
                        if(_formKey.currentState.validate()){
                          //setState(() => loading = true);
                          dynamic result = await _auth.registerWithEmailAndPassword(email, password);

                          if(result == null) {
                            setState(() {
                              //loading = false;
                              error = 'Could not sign in with those credentials';
                            });
                          } else {
                            print(result.uid);
                            DatabaseService(result.uid).configureUser(username);
                            Navigator.pop(context);
                          }

                        }
                      }
                  )
              ),

              SizedBox(height: 12.0),
              Text(
                error,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              )
            ],
          ),
        ),
        ),
      );
  }
}