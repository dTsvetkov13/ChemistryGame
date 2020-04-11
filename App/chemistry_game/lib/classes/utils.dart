import 'package:fluttertoast/fluttertoast.dart';

void showToast(var toastMsg) {
  Fluttertoast.showToast(
      msg: toastMsg.toString(),
      timeInSecForIos: 10, //TODO: set it back to 1/2 sec
      gravity: ToastGravity.BOTTOM,
      toastLength: Toast.LENGTH_SHORT);
}