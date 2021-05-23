import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyDf9-sRW0xTsOJYSPtNfTE5p8CAkRlG74M") //api key
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
