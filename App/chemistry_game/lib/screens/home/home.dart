import 'package:chemistry_game/animations/element_comet.dart';
import 'package:chemistry_game/backgrounds/home_background.dart';
import 'package:chemistry_game/models/profile_data.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:chemistry_game/screens/authenticate/login_screen.dart';
import 'package:chemistry_game/screens/authenticate/register_screen.dart';
import 'package:chemistry_game/screens/home/friends_screen.dart';
import 'package:chemistry_game/screens/home/profile_screen.dart';
import 'package:chemistry_game/screens/home/ranking_screen.dart';
import 'package:chemistry_game/services/auth.dart';
import 'package:chemistry_game/models/User.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:chemistry_game/services/database.dart';
import 'package:chemistry_game/screens/home/main_screen.dart';
import 'package:chemistry_game/constants/text_styling.dart';
import 'package:simple_animations/simple_animations.dart';

class HomeScreen extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return HomeScreenState();
  }
}

class HomeScreenState extends State<HomeScreen> {

  final AuthService _auth = AuthService();

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  var userToken;
  FirebaseMessaging _firebaseMessaging = new FirebaseMessaging();

  static var username = "";
  var singleGameWins = "";
  var teamGameWins = "";

  final HttpsCallable callGetProfileData = CloudFunctions.instance.getHttpsCallable(
    functionName: 'getProfileData',
  );

  @override
  Future<void> initState() {
    super.initState();
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) {
          var title = message["notification"]["title"];
          print("Meesage received in home");
          switch(title) {
            case ("Profile Data"):
              ProfileData.name = message["data"]["userName"];
              ProfileData.singleGameWins = message["data"]["singleGameWins"];
              ProfileData.teamGameWins = message["data"]["teamGameWins"];
              break;
            default:
          }

          return;
        }
    );
    _firebaseMessaging.getToken().then((token) async {
      userToken = token;
      print("Token : $userToken");
    });
  }

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]); //Landscape mode

    final mediaQueryData = MediaQuery.of(context);
    final mediaQueryWidth = mediaQueryData.size.width;
    final mediaQueryHeight = mediaQueryData.size.height;

    User user = Provider.of<User>(context);
    print("Third user");
    print(user.uid);
//    callGetProfileData.call({"userId": user.uid, "userToken": userToken});

    List<Widget> _widgetOptions = <Widget>[
      MainScreen(userId: user.uid),
      ProfileScreen(userId: user.uid),
      FriendsScreen(userId: user.uid,),
      RankingScreen()
    ];

    Widget drawProfileData() {
      return Column(
        children: <Widget>[
          Icon(Icons.person),
          Text(
            ProfileData.name,
            style: TextStyle(
              fontWeight: FontWeight.bold
            ),
          ),
          Text(
              "Single Player Wins: " + ProfileData.singleGameWins
          ),
          Text(
              "Team Game Wins: " + ProfileData.teamGameWins
          )
        ],
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      endDrawer: Drawer(
        child: Container(
          child: ListView(
            children: <Widget>[
              Container(
                height: mediaQueryHeight * 0.3,
                child: DrawerHeader(
                  child: ValueListenableBuilder(
                    valueListenable: ProfileData.updated,
                    child: drawProfileData(),
                    builder: (BuildContext context, bool value, Widget child) {
                      return drawProfileData();
                    },
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                  ),
                ),
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Icon(Icons.home),
                    Text(
                      "Home"
                    )
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Profile'),
                onTap: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Icon(Icons.people),
                    Text(
                      "Friends"
                    )
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Icon(Icons.assessment),
                    Text(
                        "Ranking"
                    )
                  ],
                ),
                onTap: () {
                  setState(() {
                    _selectedIndex = 3;
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Row(
                  children: <Widget>[
                    Icon(Icons.exit_to_app),
                    Text(
                        "Log Out"
                    )
                  ],
                ),
                onTap: () async {
                  await _auth.signOut();
                },
              )
            ],
          ),
        ),
      ),
      body: Builder(
        builder: (context) =>  Container(
          child: Stack(
            children: <Widget> [
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
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton(
                    icon: Icon(Icons.menu),
                    onPressed: () {
                      Scaffold.of(context).openEndDrawer();
                    },
                  )
                ],
              ),
              Center(
                child: _widgetOptions.elementAt(_selectedIndex),
              ),
          ]
          ),
        ),
      ),
    );
  }
}