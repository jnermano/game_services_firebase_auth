import 'dart:async';

import 'package:game_services_firebase_auth/game_services_platform_interface.dart';
import 'package:game_services_firebase_auth/models/access_point_location.dart';
import 'package:game_services_firebase_auth/models/achievement.dart';
import 'package:game_services_firebase_auth/models/score.dart';

class GameServicesFirebaseAuth {

  /// Unlock an [achievement].
  /// [Achievement] takes three parameters:
  /// [androidID] the achievement id for android.
  /// [iOSID] the achievement id for iOS.
  /// [percentComplete] the completion percent of the achievement, this parameter is
  /// optional in case of iOS.
  static Future<String?> unlock({achievement: Achievement}) async {
    return await GamesServicesPlatform.instance.unlock(achievement: achievement);
  }

  /// Increment an [achievement].
  /// [Achievement] takes two parameters:
  /// [androidID] the achievement id for android.
  /// [steps] If the achievement is of the incremental type
  /// you can use this method to increment the steps.
  /// * only for Android (see https://developers.google.com/games/services/android/achievements#unlocking_achievements).
  static Future<String?> increment({achievement: Achievement}) async {
    return await GamesServicesPlatform.instance.increment(achievement: achievement);
  }

  /// Submit a [score] to specific leader board.
  /// [Score] takes three parameters:
  /// [androidLeaderboardID] the leader board id that you want to send the score for in case of android.
  /// [iOSLeaderboardID] the leader board id that you want to send the score for in case of iOS.
  /// [value] the score.
  static Future<String?> submitScore({score: Score}) async {
    return await GamesServicesPlatform.instance.submitScore(score: score);
  }

  /// It will open the achievements screen.
  static Future<String?> showAchievements() async {
    return await GamesServicesPlatform.instance.showAchievements();
  }

  /// It will open the leaderboards screen.
  static Future<String?> showLeaderboards({iOSLeaderboardID = ""}) async {
    return await GamesServicesPlatform.instance.showLeaderboards(iOSLeaderboardID: iOSLeaderboardID);
  }

  /// Show the iOS Access Point.
  static Future<String?> showAccessPoint(AccessPointLocation location) async {
    return await GamesServicesPlatform.instance.showAccessPoint(location);
  }

  /// Hide the iOS Access Point.
  static Future<String?> hideAccessPoint() async {
    return await GamesServicesPlatform.instance.hideAccessPoint();
  }

  /// Try to sign in with native Game Service (Play Games on Android and GameCenter on iOS)
  /// Return `true` if success
  /// [clientId] is only for Android if you want to provide a clientId other than the main one in you google-services.json
  static Future<bool> signInWithGameService({String? clientId}) async {
    return await GamesServicesPlatform.instance.signInWithGameService(clientId: clientId);
  }

  /// Try to sign link current user with native Game Service (Play Games on Android and GameCenter on iOS)
  /// Return `true` if success
  /// [clientId] is only for Android if you want to provide a clientId other than the main one in you google-services.json
  /// [forceSignInIfCredentialAlreadyUsed] make user force sign in with game services link failed because of ERROR_CREDENTIAL_ALREADY_IN_USE
  static Future<bool> linkGameServicesCredentialsToCurrentUser(
      {String? clientId, bool forceSignInIfCredentialAlreadyUsed = false}) async {
    return await GamesServicesPlatform.instance.linkGameServicesCredentialsToCurrentUser(clientId: clientId, forceSignInIfCredentialAlreadyUsed: forceSignInIfCredentialAlreadyUsed);
  }

  /// Test if a user is already linked to a game service
  /// Advised to be call before linkGameServicesCredentialsToCurrentUser()
  static bool isUserLinkedToGameService() {
    return GamesServicesPlatform.instance.isUserLinkedToGameService();
  }
}
