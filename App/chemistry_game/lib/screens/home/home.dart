import 'package:chemistry_game/animations/element_comet.dart';
import 'package:chemistry_game/backgrounds/home_background.dart';
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

  @override
  Widget build(BuildContext context) {

    SystemChrome.setEnabledSystemUIOverlays([]);

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]); //Landscape mode

    User user = Provider.of<User>(context);
    print("Third user");
    print(user.uid);

    List<Widget> _widgetOptions = <Widget>[
      MainScreen(userId: user.uid),
      ProfileScreen(),
      FriendsScreen(),
      RankingScreen()
    ];


    //UserData userData = DatabaseService(user.uid).userDataFromSnapshot();

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            Container(
              height: 100,
              child: DrawerHeader(
                child: Text("Home Menu"),
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
              ),
            ),
            ListTile(
              title: Text('Home'),
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
              title: Text('Friends'),
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Ranking'),
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text("Log out"),
              onTap: () async {
                await _auth.signOut();
              },
            )
          ],
        ),
      ),
      body: Builder(
        builder: (context) =>  Stack(
          children: <Widget> [
            HomeBackground(),
            ElementComet(name: "H2"),
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
    );

    /*return Scaffold(
      appBar: AppBar(
        title: Text("Chemistry Game"),
        elevation: 0.0,
        actions: <Widget>[
          FlatButton.icon(
            icon: Icon(Icons.person),
            label: Text('logout'),
            onPressed: () async {
              await _auth.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[

          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text(
                'Home'
            ),
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            title: Text('Profile'),
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            title: Text('Friends'),
            backgroundColor: Colors.blue
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backup), //TODO: change the icon to something with ranking
            title: Text('Ranking'),
            backgroundColor: Colors.blue
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),


    );*/
  }
}