import "package:cloud_firestore/cloud_firestore.dart";
import 'package:flutter/material.dart';

class User {

  final String uid;

  User({this.uid});
}

class UserData {

  final String username;
  int singleGameWins;
  int teamGameWins;
  List<User> friends;

  UserData({this.username, this.singleGameWins, this.teamGameWins});
}


  /*final String username;
  final String password;
  final DocumentReference reference;

  User.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['username'] != null),
        assert(map['password'] != null),
        username = map['username'],
        password = map['password'];

  User.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
  */


