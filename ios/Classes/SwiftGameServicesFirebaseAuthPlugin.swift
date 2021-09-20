import Flutter
import UIKit
import GameKit
import os
import FirebaseAuth


public class SwiftGameServicesFirebaseAuthPlugin: NSObject, FlutterPlugin {
    
    
    var viewController: UIViewController {
        return UIApplication.shared.windows.first!.rootViewController!
    }
    
    private func getCredentialsAndSignIn(result: @escaping (Bool, FlutterError?) -> Void) {
        GameCenterAuthProvider.getCredential { cred, error in
            
            if let error = error {
                result(false, FlutterError.init(code: "get_gamecenter_credentials_failed", message: "Failed to get GameCenter credentials", details:error.localizedDescription))
                return
            }
            
            if(cred == nil) {
                result(false, FlutterError.init(code: "gamecenter_credentials_null", message: "Failed to get GameCenter credentials", details: "Credential are null"))
                return
            }
            
            Auth.auth().signIn(with:cred!) { (user, error) in
                
                if let error = error {
                    
                    
                    result(false, FlutterError.init(code: "firebase_signin_failed", message:"Failed to get sign in to Firebase", details:error.localizedDescription))
                    return
                }
                
                result(true, nil);
                return
            }
        }
    }
    
    private func getCredentialsAndLink(user: User, forceSignInIfCredentialAlreadyUsed: Bool, result: @escaping (Bool, FlutterError?) -> Void) {
        GameCenterAuthProvider.getCredential { cred, error in
            if let error = error {
                result(false, FlutterError.init(code: "get_gamecenter_credentials_failed", message: "Failed to get GameCenter credentials", details:error.localizedDescription))
                return
            }
            
            if(cred == nil) {
                result(false, FlutterError.init(code: "gamecenter_credentials_null", message: "Failed to get GameCenter credentials", details: "Credential are null"))
                return
            }
            
            user.link(with: cred!) { (authResult, error) in
                
                if let error = error {
                    guard let errorCode = AuthErrorCode(rawValue: error._code) else {
                        print("there was an error logging in but it could not be matched with a firebase code")
                        return
                    }
                    
                    let code = errorCode.rawValue == 17025 ? "ERROR_CREDENTIAL_ALREADY_IN_USE" : "${errorCode.rawValue}"
                    
                    if(code == "ERROR_CREDENTIAL_ALREADY_IN_USE" && forceSignInIfCredentialAlreadyUsed) {
                        try? Auth.auth().signOut();
                        
                        Auth.auth().signIn(with:cred!) { (user, error) in
                            if let error = error {
                                result(false, FlutterError.init(code: "firebase_signin_failed", message:"Failed to get sign in to Firebase", details:error.localizedDescription))
                                return
                            }
                            
                            result(true, nil);
                            return
                        }
                    } else {
                        result(false, FlutterError.init(code: code, message:"Failed to link credentials to Firebase User", details:error.localizedDescription))
                        return
                    }
                } else {
                    result(true, nil);
                    return
                }
            }
        }
    }
    
    
    
    
    private func signInWithGameCenter(result: @escaping (Bool, FlutterError?) -> Void) {
        let player = GKLocalPlayer.local
        
        
        // If player is already authenticated
        if(player.isAuthenticated) {
            self.getCredentialsAndSignIn(result: result)
        } else {
            player.authenticateHandler = { vc, error in
                
                if let vc = vc {
                    self.viewController.present(vc, animated: true, completion: nil)
                } else if player.isAuthenticated {
                    
                    self.getCredentialsAndSignIn(result: result)
                } else {
                    result(false, FlutterError.init(code: "no_player_detected", message: "No player detected on this phone", details:nil))
                    return
                }
            }
        }
        
    }
    
    private func linkGameCenterCredentialsToCurrentUser (forceSignInIfCredentialAlreadyUsed: Bool, result: @escaping (Bool, FlutterError?) -> Void) {
        let player = GKLocalPlayer.local
        
        let user: User? = Auth.auth().currentUser
        
        if(user == nil) {
            result(false, FlutterError.init(code: "no_user_sign_in", message: "No User sign in to Firebase, impossible to link any credentials", details:nil))
            return
        }
        
        
        for provider in user!.providerData {
            if(provider.providerID == "gc.apple.com") {
                print("User already link to Game Center")
                result(true, nil)
                return
            }
            
        }
        
        // If player is already authenticated
        if(player.isAuthenticated) {
            self.getCredentialsAndLink(user: user!, forceSignInIfCredentialAlreadyUsed: forceSignInIfCredentialAlreadyUsed, result: result)
        } else {
            player.authenticateHandler = { vc, error in
                
                if let vc = vc {
                    self.viewController.present(vc, animated: true, completion: nil)
                } else if player.isAuthenticated {
                    self.getCredentialsAndLink(user: user!, forceSignInIfCredentialAlreadyUsed: forceSignInIfCredentialAlreadyUsed, result: result)
                } else {
                    result(false, FlutterError.init(code: "no_player_detected", message: "No player detected on this phone", details:nil))
                    return
                }
            }
        }
    }
    
    
  // MARK: - Leaderboard

  func showLeaderboardWith(identifier: String) {
    let vc = GKGameCenterViewController()
    vc.gameCenterDelegate = self
    vc.viewState = .achievements
    vc.leaderboardIdentifier = identifier
    viewController.present(vc, animated: true, completion: nil)
  }

  func report(score: Int64, leaderboardID: String, result: @escaping FlutterResult) {
    let reportedScore = GKScore(leaderboardIdentifier: leaderboardID)
    reportedScore.value = score
    GKScore.report([reportedScore]) { (error) in
      guard error == nil else {
        result(error?.localizedDescription ?? "")
        return
      }
      result("success")
    }
  }

  // MARK: - Achievements

  func showAchievements() {
    let vc = GKGameCenterViewController()
    vc.gameCenterDelegate = self
    vc.viewState = .achievements
    viewController.present(vc, animated: true, completion: nil)
  }

  func report(achievementID: String, percentComplete: Double, result: @escaping FlutterResult) {
    let achievement = GKAchievement(identifier: achievementID)
    achievement.percentComplete = percentComplete
    achievement.showsCompletionBanner = true
    GKAchievement.report([achievement]) { (error) in
      guard error == nil else {
        result(error?.localizedDescription ?? "")
        return
      }
      result("success")
    }
  }
  
  // MARK: - AccessPoint

  func showAccessPoint(location: String) {
    if #available(iOS 14.0, *) {
      var gkLocation: GKAccessPoint.Location = .topLeading
      switch location {
      case "topLeading":
        gkLocation = .topLeading
      case "topTrailing":
        gkLocation = .topTrailing
      case "bottomLeading":
        gkLocation = .bottomLeading
      case "bottomTrailing":
        gkLocation = .bottomTrailing
      default:
        break
      }
      GKAccessPoint.shared.location = gkLocation
      GKAccessPoint.shared.isActive = true
    }
  }
  
  func hideAccessPoint() {
    if #available(iOS 14.0, *) {
      GKAccessPoint.shared.isActive = false
    }
  }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any]
        switch call.method {
            case "unlock":
                let achievementID = (arguments?["achievementID"] as? String) ?? ""
                let percentComplete = (arguments?["percentComplete"] as? Double) ?? 0.0
                report(achievementID: achievementID, percentComplete: percentComplete, result: result)
            case "submitScore":
                let leaderboardID = (arguments?["leaderboardID"] as? String) ?? ""
                let score = (arguments?["value"] as? Int) ?? 0
                report(score: Int64(score), leaderboardID: leaderboardID, result: result)
            case "showAchievements":
                showAchievements()
                result("success")
            case "showLeaderboards":
                let leaderboardID = (arguments?["iOSLeaderboardID"] as? String) ?? ""
                showLeaderboardWith(identifier: leaderboardID)
                result("success")
            case "hideAccessPoint":
                hideAccessPoint()
            case "showAccessPoint":
                let location = (arguments?["location"] as? String) ?? ""
                showAccessPoint(location: location)
            case "sign_in_with_game_service":
                signInWithGameCenter () { cred, error in
                    if let error = error {
                        result(error)
                    }
                    result(true)
                }
            break
            case "link_game_services_credentials_to_current_user":
                var forceSignInIfCredentialAlreadyUsed = false
            
                let args = call.arguments as? Dictionary<String, Any>
                
                if(args != nil) {
                    forceSignInIfCredentialAlreadyUsed = (args!["force_sign_in_credential_already_used"] as? Bool) ?? false
                }
                
                linkGameCenterCredentialsToCurrentUser (forceSignInIfCredentialAlreadyUsed: forceSignInIfCredentialAlreadyUsed) { cred, error in
                    if let error = error {
                        result(error)
                    }
                    result(true)
                }
            break
            default:
                self.log(message: "Unknown method called")
                result("unimplemented")
            break
        }
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "game_services_firebase_auth", binaryMessenger: registrar.messenger())
        let instance = SwiftGameServicesFirebaseAuthPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    private func log(message: StaticString) {
        if #available(iOS 10.0, *) {
            os_log(message)
        }
    }
}
