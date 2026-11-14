import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let timezoneChannel = FlutterMethodChannel(
      name: "br.com.innominata.mysweethome/timezone",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    timezoneChannel.setMethodCallHandler { call, result in
      if call.method == "getLocalTimezone" {
        result(TimeZone.current.identifier)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    let appUpdateChannel = FlutterMethodChannel(
      name: "br.com.innominata.mysweethome/app_update",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    appUpdateChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "checkForUpdate":
        result([
          "updateAvailable": false,
          "installedFromPlayStore": false,
        ])
      case "startUpdate":
        result(FlutterError(code: "UNAVAILABLE", message: "Play Store updates unavailable on iOS", details: nil))
      case "openExternalUrl":
        guard
          let args = call.arguments as? [String: Any],
          let urlString = args["url"] as? String,
          let url = URL(string: urlString)
        else {
          result(FlutterError(code: "INVALID_URL", message: "Missing or invalid URL", details: nil))
          return
        }
        DispatchQueue.main.async {
          UIApplication.shared.open(url, options: [:]) { success in
            if success {
              result(true)
            } else {
              result(FlutterError(code: "UNAVAILABLE", message: "Failed to open URL", details: nil))
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
