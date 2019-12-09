import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chemistry_game/models/User.dart';

class DatabaseService {

  final String uid;

  DatabaseService(this.uid);

  final CollectionReference usersCollection = Firestore.instance.collection("users");

  Future<void> configureUser(String username) async {
    return await usersCollection.document(uid).setData({
      'username': username,
      'singleGameWins': 0,
      'teamGameWins': 0
      //TODO :  add friends field by userId
    });
  }

  //Increase Single Game Wins by 1
  //Increase Team Game Wins by 1
  //Add friends
  //Delete friends

  UserData userDataFromSnapshot(DocumentSnapshot snapshot) {
    return UserData(
      username: snapshot.data['username'],
      singleGameWins: snapshot.data['singleGameWins'],
      teamGameWins: snapshot.data['teamGameWins']
    );
  }
}