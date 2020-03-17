import 'package:chemistry_game/screens/authenticate/authenticate.dart';
import 'package:chemistry_game/screens/game_screens/room_screen.dart';
import 'package:chemistry_game/theme/colors.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:chemistry_game/screens/home/main_screen.dart';

RemoteConfig remoteConfig;
ValueNotifier<bool> gotData = new ValueNotifier(false);

void remoteConfigInit() async {
  remoteConfig = await RemoteConfig.instance;
  remoteConfig.setConfigSettings(RemoteConfigSettings(debugMode: false));

  await remoteConfig.notifyListeners();
  await remoteConfig.fetch(expiration: const Duration(seconds: 0));
  await remoteConfig.activateFetched();

  gotData.value = true;
}

void getMainScreenData() async {
  MainScreen.singleModeText = remoteConfig.getString("singleModeText");
  MainScreen.teamModeText = remoteConfig.getString("teamModeText");
  MainScreen.playButtonText = remoteConfig.getString("playButtonText");
  MainScreen.inviteMsg = remoteConfig.getString("inviteMsg");
  MainScreen.receiveMsg = remoteConfig.getString("receiveMsg");
}

void getRoomScreenData() async {
  BuildRoomScreen.inGameMessages = remoteConfig.getString("inGameMessages");
}

void getColors() async {

}

void getAuthenticateData() async {
  AuthenticateState.mainLoginButtonText = remoteConfig.getString("mainLoginButtonText");
  AuthenticateState.secondaryLoginButtonText = remoteConfig.getString("secondaryLoginButtonText");
  AuthenticateState.mainRegisterButtonText = remoteConfig.getString("mainRegisterButtonText");
  AuthenticateState.secondaryRegisterButtonText = remoteConfig.getString("secondaryRegisterButtonText");
  AuthenticateState.informationButtonText = remoteConfig.getString("informationButtonText");
  AuthenticateState.informationText = remoteConfig.getString("informationText");
}
