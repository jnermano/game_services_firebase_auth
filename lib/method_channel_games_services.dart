import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:game_services_firebase_auth/game_service_firebase_exception.dart';
import 'game_services_platform_interface.dart';
import 'helpers.dart';
import 'models/access_point_location.dart';
import 'models/achievement.dart';
import 'models/score.dart';

const MethodChannel _channel = const MethodChannel("game_services_firebase_auth");

class MethodChannelGamesServices extends GamesServicesPlatform {
  Future<String?> unlock({achievement: Achievement}) async {
    return await _channel.invokeMethod("unlock", {
      "achievementID": achievement.id,
      "percentComplete": achievement.percentComplete,
    });
  }

  Future<String?> submitScore({score: Score}) async {
    return await _channel.invokeMethod("submitScore", {
      "leaderboardID": score.leaderboardID,
      "value": score.value,
    });
  }

  Future<String?> increment({achievement: Achievement}) async {
    return await _channel.invokeMethod("increment", {
      "achievementID": achievement.id,
      "steps": achievement.steps,
    });
  }

  Future<String?> showAchievements() async {
    return await _channel.invokeMethod("showAchievements");
  }

  Future<String?> showLeaderboards({iOSLeaderboardID = ""}) async {
    return await _channel.invokeMethod("showLeaderboards", {"iOSLeaderboardID": iOSLeaderboardID});
  }

  Future<String?> showAccessPoint(AccessPointLocation location) async {
    return await _channel.invokeMethod("showAccessPoint", {"location": location.toString().split(".").last});
  }

  Future<String?> hideAccessPoint() async {
    return await _channel.invokeMethod("hideAccessPoint");
  }

  Future<bool> signInWithGameService({String? clientId}) async {
    try {
      final dynamic result = await _channel.invokeMethod('sign_in_with_game_service', {'client_id': clientId});

      if (result is bool) {
        return result;
      } else {
        return false;
      }
    } on PlatformException catch (error) {
      String code = 'unknown';

      switch (error.code) {
        case 'ERROR_CREDENTIAL_ALREADY_IN_USE':
          code = 'credential_already_in_use';
          break;
        case 'get_gamecenter_credentials_failed':
        case 'no_player_detected':
        case '12501':
          code = 'game_service_badly_configured_user_side';
          break;
      }
      throw GameServiceFirebaseAuthException(code: code, message: error.message, stackTrace: error.stacktrace);
    } catch (error) {
      throw GameServiceFirebaseAuthException(message: error.toString());
    }
  }

  Future<bool> linkGameServicesCredentialsToCurrentUser(
      {String? clientId, bool forceSignInIfCredentialAlreadyUsed = false}) async {
    try {
      final dynamic result = await _channel.invokeMethod('link_game_services_credentials_to_current_user', {
        'client_id': clientId,
        'force_sign_in_credential_already_used': forceSignInIfCredentialAlreadyUsed,
      });

      if (result is bool) {
        return result;
      } else {
        return false;
      }
    } on PlatformException catch (error) {
      String code = 'unknown';

      switch (error.code) {
        case 'ERROR_CREDENTIAL_ALREADY_IN_USE':
          code = 'credential_already_in_use';
          break;
        case 'get_gamecenter_credentials_failed':
        case 'no_player_detected':
        case '12501':
          code = 'game_service_badly_configured_user_side';
          break;
      }
      throw GameServiceFirebaseAuthException(code: code, message: error.message, stackTrace: error.stacktrace);
    } catch (error) {
      throw GameServiceFirebaseAuthException(message: error.toString());
    }
  }

  bool isUserLinkedToGameService() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('Firebase user is null');
    }

    final isLinked = user.providerData
        .map((userInfo) => userInfo.providerId)
        .contains(Helpers.isPlatformAndroid ? 'playgames.google.com': 'gc.apple.com');

    return isLinked;
  }
}
