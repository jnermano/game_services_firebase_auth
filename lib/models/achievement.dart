import 'package:game_services_firebase_auth/helpers.dart';

class Achievement {
  String? androidID;
  String iOSID;
  double percentComplete;
  int steps;

  String? get id {
    return Helpers.isPlatformAndroid ? androidID : iOSID;
  }

  Achievement({this.androidID, this.iOSID = "", this.percentComplete = 100, this.steps = 0});
}
