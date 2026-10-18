import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // the plugin shows notifications in front and hands taps to dart through this delegate
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    // mark prayed from a notification runs dart in a background engine, it needs the plugins too
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "BackupExclusion") {
      registerBackupExclusion(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PowerSaving") {
      registerPowerSaving(messenger: registrar.messenger())
    }
  }

  /// iCloud backs Application Support up, the store has to stay on this phone (FR-023)
  private func registerBackupExclusion(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "better_muslim/backup", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "exclude", let path = call.arguments as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        result(nil)
      } catch {
        // only the error code, the description can hold the path
        let code = (error as NSError).code
        result(FlutterError(code: "exclude_failed", message: "\(code)", details: nil))
      }
    }
  }

  /// home's sky pauses its ambient motion in low power mode (MOTION tiers)
  private func registerPowerSaving(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "better_muslim/power", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "isPowerSaving" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(ProcessInfo.processInfo.isLowPowerModeEnabled)
    }
  }
}
