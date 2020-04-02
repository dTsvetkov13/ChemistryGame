import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class DatabaseService {

  final String uid;

  DatabaseService(this.uid);

  final CollectionReference usersCollection = Firestore.instance.collection("users");

  Future<void> configureUser(String username, String email) async {

    final HttpsCallable updateUser = CloudFunctions(region: "europe-west1").getHttpsCallable(
      functionName: 'updateUser',
    );

    var user = {
      "id" : uid,
      "username" : username,
      'singleGameWins': 0,
      'teamGameWins': 0,
      "email": email
    };

    await updateUser.call(user);
  }
}