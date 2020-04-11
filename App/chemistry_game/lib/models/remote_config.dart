import 'package:chemistry_game/screens/authenticate/authenticate.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:chemistry_game/screens/home/main_screen.dart';

class Config {
  RemoteConfig remoteConfig;
  ValueNotifier<bool> gotData = new ValueNotifier(false);
  static final Config _instance = Config._privateConstructor();
  Map<String, String> strings = new Map<String, String>();

  Config._privateConstructor();

  factory Config() {
    return _instance;
  }

  void getAllData() async {
    remoteConfig = await RemoteConfig.instance;
    remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: false));

    await remoteConfig.notifyListeners();
    await remoteConfig.fetch(expiration: const Duration(seconds: 0));
    await remoteConfig.activateFetched();

    gotData.value = true;

    remoteConfig.getAll().forEach((key, value) => {
      strings[key] = value.asString()
    });
  }

  String getString(String key) {
    return strings[key];
  }
}
